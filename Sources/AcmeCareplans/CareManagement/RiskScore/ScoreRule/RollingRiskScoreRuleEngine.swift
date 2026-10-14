import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling risk score rule calculation.
    protocol RollingRiskScoreRuleStep {
        func describe() -> String
        func adjust(_ item: RollingRiskScoreRule, value: Double) -> Double
    }

    final class TieredRollingRiskScoreRuleAdjuster: RollingRiskScoreRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingRiskScoreRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRollingRiskScoreRuleAdjuster: RollingRiskScoreRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingRiskScoreRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRollingRiskScoreRuleAdjuster: RollingRiskScoreRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingRiskScoreRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRollingRiskScoreRuleAdjuster: RollingRiskScoreRuleStep {
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

        func adjust(_ item: RollingRiskScoreRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingRiskScoreRuleSequenceOffsetAdjuster: RollingRiskScoreRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: RollingRiskScoreRule, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the rolling risk score rule steps in order and keeps a trace of each.
    final class RollingRiskScoreRuleEngine {
        var steps: [any RollingRiskScoreRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingRiskScoreRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingRiskScoreRule) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingRiskScoreRuleStep = steps[index]
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

        func evaluateAll(_ items: [RollingRiskScoreRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingRiskScoreRuleEngine(_ flags: Kit.Flags.Registry) -> RollingRiskScoreRuleEngine {
        return RollingRiskScoreRuleEngine(
            steps: [
                TieredRollingRiskScoreRuleAdjuster(bounds: [6702.0, 9120.0, 9457.0], rates: [1.19, 1.08, 0.85]),
                RoundingRollingRiskScoreRuleAdjuster(step: 1.0),
                PercentRollingRiskScoreRuleAdjuster(percent: -7.8),
                FlaggedRollingRiskScoreRuleAdjuster(
                    flags: flags,
                    flag: "rolling-risk-score-rule-fallback",
                    percent: 4.8
                ),
                RollingRiskScoreRuleSequenceOffsetAdjuster(weight: 0.56),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 39725.0
        )
    }
}
