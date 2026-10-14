import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility rule calculation.
    protocol EligibilityRuleFactor {
        func describe() -> String
        func adjust(_ item: EligibilityRule, value: Double) -> Double
    }

    final class RoundingEligibilityRuleAdjuster: EligibilityRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredEligibilityRuleAdjuster: EligibilityRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapEligibilityRuleAdjuster: EligibilityRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the eligibility rule steps in order and keeps a trace of each.
    final class EligibilityRuleEngine {
        var steps: [any EligibilityRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: EligibilityRule) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityRuleFactor = steps[index]
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

        func evaluateAll(_ items: [EligibilityRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultEligibilityRuleEngine() -> EligibilityRuleEngine {
        return EligibilityRuleEngine(
            steps: [
                RoundingEligibilityRuleAdjuster(step: 0.05),
                TieredEligibilityRuleAdjuster(bounds: [7978.0, 8625.0], rates: [1.13, 0.87]),
                CapEligibilityRuleAdjuster(cap: 5911.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 92962.1
        )
    }
}
