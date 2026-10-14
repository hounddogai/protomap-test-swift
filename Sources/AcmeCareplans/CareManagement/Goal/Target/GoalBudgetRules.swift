import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal budget must pass. Check returns its problems, or none.
    protocol GoalBudgetRule {
        func check(_ item: GoalBudget) -> [String]
    }

    final class GoalBudgetRequiredCodeRule: GoalBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalBudgetCodeLengthRule: GoalBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalBudgetCodePrefixRule: GoalBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal budget.
    final class GoalBudgetValidator {
        var rules: [any GoalBudgetRule]

        init(rules: [any GoalBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalBudget) -> [String] {
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

        func requireValid(_ item: GoalBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalBudget]) -> [String: [String]] {
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

    static func defaultGoalBudgetValidator() -> GoalBudgetValidator {
        return GoalBudgetValidator(
            rules: [
                GoalBudgetRequiredCodeRule(message: "goal budget needs this field"),
                GoalBudgetCodeLengthRule(maxLength: 120),
                GoalBudgetCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
