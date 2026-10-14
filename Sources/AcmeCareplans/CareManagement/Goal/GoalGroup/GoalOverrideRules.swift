import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal override must pass. Check returns its problems, or none.
    protocol GoalOverrideRule {
        func check(_ item: GoalOverride) -> [String]
    }

    final class GoalOverrideSequenceRangeRule: GoalOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalOverride) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalOverrideRequiredNameRule: GoalOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalOverride) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalOverrideWeightRangeRule: GoalOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalOverride) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalOverrideThresholdRangeRule: GoalOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalOverride) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GoalOverrideDiagnosisCodeLengthRule: GoalOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalOverride) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal override.
    final class GoalOverrideValidator {
        var rules: [any GoalOverrideRule]

        init(rules: [any GoalOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalOverride]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultGoalOverrideValidator() -> GoalOverrideValidator {
        return GoalOverrideValidator(
            rules: [
                GoalOverrideSequenceRangeRule(min: 80, max: 1000),
                GoalOverrideRequiredNameRule(message: "goal override needs an entry"),
                GoalOverrideWeightRangeRule(min: 0.8, max: 944.7),
                GoalOverrideThresholdRangeRule(min: 2.2, max: 103.8),
                GoalOverrideDiagnosisCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
