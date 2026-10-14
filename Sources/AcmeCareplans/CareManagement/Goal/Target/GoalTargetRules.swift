import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal target must pass. Check returns its problems, or none.
    protocol GoalTargetRule {
        func check(_ item: GoalTarget) -> [String]
    }

    final class GoalTargetRequiredNameRule: GoalTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalTargetUnitLengthRule: GoalTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalTarget) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalTargetCodeLengthRule: GoalTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalTargetDurationMinutesRangeRule: GoalTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalTarget) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GoalTargetCategoryLengthRule: GoalTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalTarget) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal target.
    final class GoalTargetValidator {
        var rules: [any GoalTargetRule]

        init(rules: [any GoalTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: GoalTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalTarget]) -> [String: [String]] {
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

    static func defaultGoalTargetValidator() -> GoalTargetValidator {
        return GoalTargetValidator(
            rules: [
                GoalTargetRequiredNameRule(message: "goal target needs a value"),
                GoalTargetUnitLengthRule(maxLength: 16),
                GoalTargetCodeLengthRule(maxLength: 64),
                GoalTargetDurationMinutesRangeRule(min: 16, max: 255),
                GoalTargetCategoryLengthRule(maxLength: 16),
            ]
        )
    }
}
