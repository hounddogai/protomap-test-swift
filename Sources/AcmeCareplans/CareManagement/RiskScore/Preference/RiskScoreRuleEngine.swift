import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score rule calculation.
    protocol RiskScoreRuleStep {
        func describe() -> String
        func adjust(_ item: RiskScoreRule, value: Double) -> Double
    }

    final class TieredRiskScoreRuleAdjuster: RiskScoreRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RiskScoreRuleWeightOffsetAdjuster: RiskScoreRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: RiskScoreRule, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class MinimumRiskScoreRuleAdjuster: RiskScoreRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the risk score rule steps in order and keeps a trace of each.
    final class RiskScoreRuleEngine {
        var steps: [any RiskScoreRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RiskScoreRule) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreRuleStep = steps[index]
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

        func evaluateAll(_ items: [RiskScoreRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRiskScoreRuleEngine() -> RiskScoreRuleEngine {
        return RiskScoreRuleEngine(
            steps: [
                TieredRiskScoreRuleAdjuster(bounds: [3848.0, 4367.0], rates: [1.07, 1.05]),
                RiskScoreRuleWeightOffsetAdjuster(weight: 1.61),
                MinimumRiskScoreRuleAdjuster(minimum: 14.8),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 95147.8
        )
    }
}
