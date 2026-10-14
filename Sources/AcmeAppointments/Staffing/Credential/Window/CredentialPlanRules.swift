import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential plan must pass. Check returns its problems, or none.
    protocol CredentialPlanRule {
        func check(_ item: CredentialPlan) -> [String]
    }

    final class CredentialPlanDescriptionLengthRule: CredentialPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialPlan) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialPlanCodeLengthRule: CredentialPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialPlanRequiredTitleRule: CredentialPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialPlanCodePrefixRule: CredentialPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential plan.
    final class CredentialPlanValidator {
        var rules: [any CredentialPlanRule]

        init(rules: [any CredentialPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialPlan]) -> [String: [String]] {
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

    static func defaultCredentialPlanValidator() -> CredentialPlanValidator {
        return CredentialPlanValidator(
            rules: [
                CredentialPlanDescriptionLengthRule(maxLength: 64),
                CredentialPlanCodeLengthRule(maxLength: 3600),
                CredentialPlanRequiredTitleRule(message: "credential plan needs an entry"),
                CredentialPlanCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
