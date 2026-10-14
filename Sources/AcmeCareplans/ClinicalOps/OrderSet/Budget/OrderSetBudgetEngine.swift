import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set budget calculation.
    protocol OrderSetBudgetFactor {
        func describe() -> String
        func adjust(_ item: OrderSetBudget, value: Double) -> Double
    }

    final class TieredOrderSetBudgetAdjuster: OrderSetBudgetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentOrderSetBudgetAdjuster: OrderSetBudgetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedOrderSetBudgetAdjuster: OrderSetBudgetFactor {
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

        func adjust(_ item: OrderSetBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the order set budget steps in order and keeps a trace of each.
    final class OrderSetBudgetEngine {
        var steps: [any OrderSetBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OrderSetBudget) -> Double {
            var current = item.measuredValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [OrderSetBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOrderSetBudgetEngine(_ flags: Kit.Flags.Registry) -> OrderSetBudgetEngine {
        return OrderSetBudgetEngine(
            steps: [
                TieredOrderSetBudgetAdjuster(bounds: [1034.0, 4223.0], rates: [0.97, 1.01]),
                PercentOrderSetBudgetAdjuster(percent: 5.6),
                FlaggedOrderSetBudgetAdjuster(flags: flags, flag: "order-set-budget-tiered", percent: 0.3),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 39708.2
        )
    }
}
