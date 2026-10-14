import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential rule must pass. Check returns its problems, or none.
    protocol CredentialRuleRule {
        func check(_ item: CredentialRule) -> [String]
    }

    final class CredentialRuleRateRangeRule: CredentialRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialRule) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialRuleRequiredTitleRule: CredentialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialRuleContactEmailLengthRule: CredentialRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialRule) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialRuleRequiredContactEmailRule: CredentialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialRule) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential rule.
    final class CredentialRuleValidator {
        var rules: [any CredentialRuleRule]

        init(rules: [any CredentialRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialRule]) -> [String: [String]] {
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

    static func defaultCredentialRuleValidator() -> CredentialRuleValidator {
        return CredentialRuleValidator(
            rules: [
                CredentialRuleRateRangeRule(min: 5.9, max: 302.9),
                CredentialRuleRequiredTitleRule(message: "credential rule needs a value"),
                CredentialRuleContactEmailLengthRule(maxLength: 255),
                CredentialRuleRequiredContactEmailRule(message: "credential rule needs this field"),
            ]
        )
    }
}
