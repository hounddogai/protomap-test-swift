import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered proxy budget calculation.
    protocol TieredProxyBudgetFactor {
        func describe() -> String
        func adjust(_ item: TieredProxyBudget, value: Double) -> Double
    }

    final class TieredProxyBudgetBudgetOffsetAdjuster: TieredProxyBudgetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: TieredProxyBudget, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class TieredTieredProxyBudgetAdjuster: TieredProxyBudgetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredProxyBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingTieredProxyBudgetAdjuster: TieredProxyBudgetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredProxyBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedTieredProxyBudgetAdjuster: TieredProxyBudgetFactor {
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

        func adjust(_ item: TieredProxyBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryTieredProxyBudgetAdjuster: TieredProxyBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: TieredProxyBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered proxy budget steps in order and keeps a trace of each.
    final class TieredProxyBudgetEngine {
        var steps: [any TieredProxyBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredProxyBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredProxyBudget) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredProxyBudgetFactor = steps[index]
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

        func evaluateAll(_ items: [TieredProxyBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredProxyBudgetEngine(_ flags: Kit.Flags.Registry) -> TieredProxyBudgetEngine {
        return TieredProxyBudgetEngine(
            steps: [
                TieredProxyBudgetBudgetOffsetAdjuster(weight: 0.16),
                TieredTieredProxyBudgetAdjuster(
                    bounds: [1260.0, 2250.0, 4066.0, 5764.0],
                    rates: [0.88, 0.84, 1.13, 1.08]
                ),
                RoundingTieredProxyBudgetAdjuster(step: 0.05),
                FlaggedTieredProxyBudgetAdjuster(flags: flags, flag: "tiered-proxy-budget-legacy", percent: 7.9),
                CategoryTieredProxyBudgetAdjuster(factors: ["retail": 1.33]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 77031.9
        )
    }
}
