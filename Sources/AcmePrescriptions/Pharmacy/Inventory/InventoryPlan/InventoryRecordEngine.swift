import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory record calculation.
    protocol InventoryRecordAdjuster {
        func describe() -> String
        func adjust(_ item: InventoryRecord, value: Double) -> Double
    }

    final class RoundingInventoryRecordAdjuster: InventoryRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredInventoryRecordAdjuster: InventoryRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumInventoryRecordAdjuster: InventoryRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleInventoryRecordAdjuster: InventoryRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: InventoryRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentInventoryRecordAdjuster: InventoryRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedInventoryRecordAdjuster: InventoryRecordAdjuster {
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

        func adjust(_ item: InventoryRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the inventory record steps in order and keeps a trace of each.
    final class InventoryRecordEngine {
        var steps: [any InventoryRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InventoryRecord) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [InventoryRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInventoryRecordEngine(_ flags: Kit.Flags.Registry) -> InventoryRecordEngine {
        return InventoryRecordEngine(
            steps: [
                RoundingInventoryRecordAdjuster(step: 0.05),
                TieredInventoryRecordAdjuster(
                    bounds: [772.0, 1783.0, 5010.0, 9314.0],
                    rates: [0.98, 1.17, 0.85, 1.07]
                ),
                MinimumInventoryRecordAdjuster(minimum: 39.2),
                TitleInventoryRecordAdjuster(factors: ["west": 1.1, "retail": 0.86]),
                PercentInventoryRecordAdjuster(percent: -15.8),
                FlaggedInventoryRecordAdjuster(flags: flags, flag: "inventory-record-global", percent: 3.3),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 29310.1
        )
    }
}
