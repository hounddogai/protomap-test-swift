import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization budget must pass. Check returns its problems, or none.
    protocol AuthorizationBudgetRule {
        func check(_ item: AuthorizationBudget) -> [String]
    }

    final class AuthorizationBudgetCodeLengthRule: AuthorizationBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationBudgetRequiredSummaryRule: AuthorizationBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationBudget) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationBudgetCodePrefixRule: AuthorizationBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationBudgetRequiredDiagnosisCodeRule: AuthorizationBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationBudget) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationBudgetSummaryLengthRule: AuthorizationBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationBudget) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization budget.
    final class AuthorizationBudgetValidator {
        var rules: [any AuthorizationBudgetRule]

        init(rules: [any AuthorizationBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationBudget) -> [String] {
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

        func requireValid(_ item: AuthorizationBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationBudget]) -> [String: [String]] {
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

    static func defaultAuthorizationBudgetValidator() -> AuthorizationBudgetValidator {
        return AuthorizationBudgetValidator(
            rules: [
                AuthorizationBudgetCodeLengthRule(maxLength: 120),
                AuthorizationBudgetRequiredSummaryRule(message: "authorization budget needs a value"),
                AuthorizationBudgetCodePrefixRule(prefix: "OPS"),
                AuthorizationBudgetRequiredDiagnosisCodeRule(message: "authorization budget needs a value"),
                AuthorizationBudgetSummaryLengthRule(maxLength: 86400),
            ]
        )
    }
}
