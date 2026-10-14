import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling follow up rule calculation.
    protocol RollingFollowUpRuleStep {
        func describe() -> String
        func adjust(_ item: RollingFollowUpRule, value: Double) -> Double
    }

    final class PercentRollingFollowUpRuleAdjuster: RollingFollowUpRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingFollowUpRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingFollowUpRuleAdjuster: RollingFollowUpRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingFollowUpRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRollingFollowUpRuleAdjuster: RollingFollowUpRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingFollowUpRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling follow up rule steps in order and keeps a trace of each.
    final class RollingFollowUpRuleEngine {
        var steps: [any RollingFollowUpRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingFollowUpRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingFollowUpRule) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingFollowUpRuleStep = steps[index]
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

        func evaluateAll(_ items: [RollingFollowUpRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingFollowUpRuleEngine() -> RollingFollowUpRuleEngine {
        return RollingFollowUpRuleEngine(
            steps: [
                PercentRollingFollowUpRuleAdjuster(percent: 6.2),
                RoundingRollingFollowUpRuleAdjuster(step: 5.0),
                TieredRollingFollowUpRuleAdjuster(bounds: [1519.0, 4444.0], rates: [1.06, 1.17]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 87959.7
        )
    }
}
