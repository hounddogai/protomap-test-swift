import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory metric calculation.
    protocol InventoryMetricStep {
        func describe() -> String
        func adjust(_ item: InventoryMetric, value: Double) -> Double
    }

    final class FlaggedInventoryMetricAdjuster: InventoryMetricStep {
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

        func adjust(_ item: InventoryMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingInventoryMetricAdjuster: InventoryMetricStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredInventoryMetricAdjuster: InventoryMetricStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumInventoryMetricAdjuster: InventoryMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the inventory metric steps in order and keeps a trace of each.
    final class InventoryMetricEngine {
        var steps: [any InventoryMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InventoryMetric) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryMetricStep = steps[index]
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

        func evaluateAll(_ items: [InventoryMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInventoryMetricEngine(_ flags: Kit.Flags.Registry) -> InventoryMetricEngine {
        return InventoryMetricEngine(
            steps: [
                FlaggedInventoryMetricAdjuster(flags: flags, flag: "inventory-metric-strict", percent: -8.8),
                RoundingInventoryMetricAdjuster(step: 5.0),
                TieredInventoryMetricAdjuster(bounds: [234.0, 4988.0, 7902.0, 9590.0], rates: [1.14, 0.88, 0.92, 1.1]),
                MinimumInventoryMetricAdjuster(minimum: 34.2),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 56764.6
        )
    }
}
