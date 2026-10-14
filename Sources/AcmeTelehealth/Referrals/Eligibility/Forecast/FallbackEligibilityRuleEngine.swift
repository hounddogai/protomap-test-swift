import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback eligibility rule calculation.
    protocol FallbackEligibilityRuleFactor {
        func describe() -> String
        func adjust(_ item: FallbackEligibilityRule, value: Double) -> Double
    }

    final class RoundingFallbackEligibilityRuleAdjuster: FallbackEligibilityRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackEligibilityRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackEligibilityRuleAdjuster: FallbackEligibilityRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackEligibilityRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackEligibilityRuleGraceDaysOffsetAdjuster: FallbackEligibilityRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: FallbackEligibilityRule, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumFallbackEligibilityRuleAdjuster: FallbackEligibilityRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackEligibilityRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFallbackEligibilityRuleAdjuster: FallbackEligibilityRuleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackEligibilityRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleFallbackEligibilityRuleAdjuster: FallbackEligibilityRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackEligibilityRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback eligibility rule steps in order and keeps a trace of each.
    final class FallbackEligibilityRuleEngine {
        var steps: [any FallbackEligibilityRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackEligibilityRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackEligibilityRule) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackEligibilityRuleFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackEligibilityRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackEligibilityRuleEngine() -> FallbackEligibilityRuleEngine {
        return FallbackEligibilityRuleEngine(
            steps: [
                RoundingFallbackEligibilityRuleAdjuster(step: 0.1),
                TieredFallbackEligibilityRuleAdjuster(bounds: [4600.0, 9981.0], rates: [1.05, 0.87]),
                FallbackEligibilityRuleGraceDaysOffsetAdjuster(weight: 0.97),
                MinimumFallbackEligibilityRuleAdjuster(minimum: 45.3),
                PercentFallbackEligibilityRuleAdjuster(percent: -17.4),
                TitleFallbackEligibilityRuleAdjuster(factors: ["east": 1.35]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 84732.1
        )
    }
}
