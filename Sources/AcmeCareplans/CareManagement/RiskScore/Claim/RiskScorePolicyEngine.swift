import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score policy calculation.
    protocol RiskScorePolicyModifier {
        func describe() -> String
        func adjust(_ item: RiskScorePolicy, value: Double) -> Double
    }

    final class FlaggedRiskScorePolicyAdjuster: RiskScorePolicyModifier {
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

        func adjust(_ item: RiskScorePolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRiskScorePolicyAdjuster: RiskScorePolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScorePolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryRiskScorePolicyAdjuster: RiskScorePolicyModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RiskScorePolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the risk score policy steps in order and keeps a trace of each.
    final class RiskScorePolicyEngine {
        var steps: [any RiskScorePolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScorePolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RiskScorePolicy) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScorePolicyModifier = steps[index]
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

        func evaluateAll(_ items: [RiskScorePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRiskScorePolicyEngine(_ flags: Kit.Flags.Registry) -> RiskScorePolicyEngine {
        return RiskScorePolicyEngine(
            steps: [
                FlaggedRiskScorePolicyAdjuster(flags: flags, flag: "risk-score-policy-default", percent: -8.6),
                PercentRiskScorePolicyAdjuster(percent: -7.7),
                CategoryRiskScorePolicyAdjuster(factors: ["south": 1.25]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 27258.5
        )
    }
}
