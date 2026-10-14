import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory segment calculation.
    protocol InventorySegmentStep {
        func describe() -> String
        func adjust(_ item: InventorySegment, value: Double) -> Double
    }

    final class CapInventorySegmentAdjuster: InventorySegmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventorySegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentInventorySegmentAdjuster: InventorySegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventorySegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceInventorySegmentAdjuster: InventorySegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: InventorySegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredInventorySegmentAdjuster: InventorySegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventorySegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumInventorySegmentAdjuster: InventorySegmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventorySegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedInventorySegmentAdjuster: InventorySegmentStep {
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

        func adjust(_ item: InventorySegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the inventory segment steps in order and keeps a trace of each.
    final class InventorySegmentEngine {
        var steps: [any InventorySegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventorySegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InventorySegment) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any InventorySegmentStep = steps[index]
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

        func evaluateAll(_ items: [InventorySegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInventorySegmentEngine(_ flags: Kit.Flags.Registry) -> InventorySegmentEngine {
        return InventorySegmentEngine(
            steps: [
                CapInventorySegmentAdjuster(cap: 32773.0),
                PercentInventorySegmentAdjuster(percent: 4.3),
                SourceInventorySegmentAdjuster(factors: ["west": 1.38]),
                TieredInventorySegmentAdjuster(
                    bounds: [2960.0, 3939.0, 6404.0, 7022.0],
                    rates: [0.98, 0.92, 0.84, 1.1]
                ),
                MinimumInventorySegmentAdjuster(minimum: 46.1),
                FlaggedInventorySegmentAdjuster(flags: flags, flag: "inventory-segment-pending", percent: -3.3),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 17836.0
        )
    }
}
