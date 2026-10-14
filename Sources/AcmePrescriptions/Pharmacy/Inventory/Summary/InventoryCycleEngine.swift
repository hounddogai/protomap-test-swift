import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory cycle calculation.
    protocol InventoryCycleAdjuster {
        func describe() -> String
        func adjust(_ item: InventoryCycle, value: Double) -> Double
    }

    final class CapInventoryCycleAdjuster: InventoryCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumInventoryCycleAdjuster: InventoryCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class InventoryCycleUpdatedAtOffsetAdjuster: InventoryCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: InventoryCycle, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class RoundingInventoryCycleAdjuster: InventoryCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedInventoryCycleAdjuster: InventoryCycleAdjuster {
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

        func adjust(_ item: InventoryCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentInventoryCycleAdjuster: InventoryCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the inventory cycle steps in order and keeps a trace of each.
    final class InventoryCycleEngine {
        var steps: [any InventoryCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InventoryCycle) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [InventoryCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInventoryCycleEngine(_ flags: Kit.Flags.Registry) -> InventoryCycleEngine {
        return InventoryCycleEngine(
            steps: [
                CapInventoryCycleAdjuster(cap: 28932.0),
                MinimumInventoryCycleAdjuster(minimum: 48.9),
                InventoryCycleUpdatedAtOffsetAdjuster(weight: 0.49),
                RoundingInventoryCycleAdjuster(step: 0.25),
                FlaggedInventoryCycleAdjuster(flags: flags, flag: "inventory-cycle-batched", percent: -3.5),
                PercentInventoryCycleAdjuster(percent: 22.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 97173.2
        )
    }
}
