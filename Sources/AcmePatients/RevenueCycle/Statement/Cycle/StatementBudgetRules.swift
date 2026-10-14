import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement budget must pass. Check returns its problems, or none.
    protocol StatementBudgetRule {
        func check(_ item: StatementBudget) -> [String]
    }

    final class StatementBudgetAllergyLengthRule: StatementBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementBudget) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementBudgetRequiredCodeRule: StatementBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementBudgetRequiredPayerRule: StatementBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementBudget) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement budget.
    final class StatementBudgetValidator {
        var rules: [any StatementBudgetRule]

        init(rules: [any StatementBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementBudget]) -> [String: [String]] {
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

    static func defaultStatementBudgetValidator() -> StatementBudgetValidator {
        return StatementBudgetValidator(
            rules: [
                StatementBudgetAllergyLengthRule(maxLength: 3600),
                StatementBudgetRequiredCodeRule(message: "statement budget needs this field"),
                StatementBudgetRequiredPayerRule(message: "statement budget needs this field"),
            ]
        )
    }
}
