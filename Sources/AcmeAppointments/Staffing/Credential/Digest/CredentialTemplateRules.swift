import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential template must pass. Check returns its problems, or none.
    protocol CredentialTemplateRule {
        func check(_ item: CredentialTemplate) -> [String]
    }

    final class CredentialTemplateRequiredTitleRule: CredentialTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialTemplateRequiredPhoneRule: CredentialTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialTemplate) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialTemplateMinimumRangeRule: CredentialTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialTemplate) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialTemplateCodePrefixRule: CredentialTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialTemplateTitleLengthRule: CredentialTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential template.
    final class CredentialTemplateValidator {
        var rules: [any CredentialTemplateRule]

        init(rules: [any CredentialTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialTemplate]) -> [String: [String]] {
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

    static func defaultCredentialTemplateValidator() -> CredentialTemplateValidator {
        return CredentialTemplateValidator(
            rules: [
                CredentialTemplateRequiredTitleRule(message: "credential template needs this field"),
                CredentialTemplateRequiredPhoneRule(message: "credential template needs this field"),
                CredentialTemplateMinimumRangeRule(min: 8.5, max: 1798.7),
                CredentialTemplateCodePrefixRule(prefix: "Q"),
                CredentialTemplateTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
