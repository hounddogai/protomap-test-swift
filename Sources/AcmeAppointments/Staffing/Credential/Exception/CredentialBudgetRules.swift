import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential budget must pass. Check returns its problems, or none.
    protocol CredentialBudgetRule {
        func check(_ item: CredentialBudget) -> [String]
    }

    final class CredentialBudgetRequiredNameRule: CredentialBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialBudgetPayerLengthRule: CredentialBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialBudget) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialBudgetRequiredPayerRule: CredentialBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialBudget) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential budget.
    final class CredentialBudgetValidator {
        var rules: [any CredentialBudgetRule]

        init(rules: [any CredentialBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialBudget) -> [String] {
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

        func requireValid(_ item: CredentialBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialBudget]) -> [String: [String]] {
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

    static func defaultCredentialBudgetValidator() -> CredentialBudgetValidator {
        return CredentialBudgetValidator(
            rules: [
                CredentialBudgetRequiredNameRule(message: "credential budget needs this field"),
                CredentialBudgetPayerLengthRule(maxLength: 1000),
                CredentialBudgetRequiredPayerRule(message: "credential budget needs this field"),
            ]
        )
    }
}
