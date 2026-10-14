import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential summary must pass. Check returns its problems, or none.
    protocol CredentialSummaryRule {
        func check(_ item: CredentialSummary) -> [String]
    }

    final class CredentialSummaryRequiredAllergyRule: CredentialSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialSummary) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialSummaryRequiredCodeRule: CredentialSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialSummaryAllowedChannelRule: CredentialSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a credential summary.
    final class CredentialSummaryValidator {
        var rules: [any CredentialSummaryRule]

        init(rules: [any CredentialSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialSummary) -> [String] {
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

        func requireValid(_ item: CredentialSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialSummary]) -> [String: [String]] {
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

    static func defaultCredentialSummaryValidator() -> CredentialSummaryValidator {
        return CredentialSummaryValidator(
            rules: [
                CredentialSummaryRequiredAllergyRule(message: "credential summary needs this field"),
                CredentialSummaryRequiredCodeRule(message: "credential summary needs a value"),
                CredentialSummaryAllowedChannelRule(allowed: ["weighted", "legacy"]),
            ]
        )
    }
}
