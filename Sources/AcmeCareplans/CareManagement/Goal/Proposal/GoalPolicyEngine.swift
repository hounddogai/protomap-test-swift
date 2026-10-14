import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal policy calculation.
    protocol GoalPolicyStep {
        func describe() -> String
        func adjust(_ item: GoalPolicy, value: Double) -> Double
    }

    final class RoundingGoalPolicyAdjuster: GoalPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGoalPolicyAdjuster: GoalPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryGoalPolicyAdjuster: GoalPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: GoalPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedGoalPolicyAdjuster: GoalPolicyStep {
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

        func adjust(_ item: GoalPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal policy steps in order and keeps a trace of each.
    final class GoalPolicyEngine {
        var steps: [any GoalPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GoalPolicy) -> Double {
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

        func evaluateAll(_ items: [GoalPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGoalPolicyEngine(_ flags: Kit.Flags.Registry) -> GoalPolicyEngine {
        return GoalPolicyEngine(
            steps: [
                RoundingGoalPolicyAdjuster(step: 1.0),
                PercentGoalPolicyAdjuster(percent: -15.7),
                CountryGoalPolicyAdjuster(factors: ["east": 0.83, "west": 1.1, "south": 1.12]),
                FlaggedGoalPolicyAdjuster(flags: flags, flag: "goal-policy-global", percent: -2.9),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 57217.9
        )
    }
}
