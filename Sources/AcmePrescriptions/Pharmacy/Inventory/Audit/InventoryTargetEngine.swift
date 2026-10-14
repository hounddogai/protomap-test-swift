import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory target calculation.
    protocol InventoryTargetFactor {
        func describe() -> String
        func adjust(_ item: InventoryTarget, value: Double) -> Double
    }

    final class FlaggedInventoryTargetAdjuster: InventoryTargetFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: InventoryTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class InventoryTargetBatchSizeOffsetAdjuster: InventoryTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: InventoryTarget, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class CapInventoryTargetAdjuster: InventoryTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumInventoryTargetAdjuster: InventoryTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredInventoryTargetAdjuster: InventoryTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the inventory target steps in order and keeps a trace of each.
    final class InventoryTargetEngine {
        var steps: [any InventoryTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InventoryTarget) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryTargetFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [InventoryTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInventoryTargetEngine(_ flags: Kit.Flags.Registry) -> InventoryTargetEngine {
        return InventoryTargetEngine(
            steps: [
                FlaggedInventoryTargetAdjuster(flags: flags, flag: "inventory-target-manual", percent: 1.9),
                InventoryTargetBatchSizeOffsetAdjuster(weight: 0.81),
                CapInventoryTargetAdjuster(cap: 27535.0),
                MinimumInventoryTargetAdjuster(minimum: 35.4),
                TieredInventoryTargetAdjuster(bounds: [7475.0, 9652.0], rates: [0.96, 0.94]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 15107.5
        )
    }
}
