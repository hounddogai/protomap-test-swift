import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal entry must pass. Check returns its problems, or none.
    protocol GoalEntryRule {
        func check(_ item: GoalEntry) -> [String]
    }

    final class GoalEntryRequiredCodeRule: GoalEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalEntryVisibleGuardRule: GoalEntryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GoalEntry) -> [String] {
            if item.visible && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class GoalEntryTitleLengthRule: GoalEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal entry.
    final class GoalEntryValidator {
        var rules: [any GoalEntryRule]

        init(rules: [any GoalEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalEntry]) -> [String: [String]] {
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

    static func defaultGoalEntryValidator() -> GoalEntryValidator {
        return GoalEntryValidator(
            rules: [
                GoalEntryRequiredCodeRule(message: "goal entry needs this field"),
                GoalEntryVisibleGuardRule(limit: 3600),
                GoalEntryTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
