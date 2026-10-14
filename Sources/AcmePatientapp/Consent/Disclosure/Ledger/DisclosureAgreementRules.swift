import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure agreement must pass. Check returns its problems, or none.
    protocol DisclosureAgreementRule {
        func check(_ item: DisclosureAgreement) -> [String]
    }

    final class DisclosureAgreementCodePrefixRule: DisclosureAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureAgreementAllowedCodeRule: DisclosureAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class DisclosureAgreementRequiredLocaleRule: DisclosureAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureAgreement) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureAgreementCreatedAtRangeRule: DisclosureAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureAgreement) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureAgreementTitleLengthRule: DisclosureAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure agreement.
    final class DisclosureAgreementValidator {
        var rules: [any DisclosureAgreementRule]

        init(rules: [any DisclosureAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureAgreement]) -> [String: [String]] {
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

    static func defaultDisclosureAgreementValidator() -> DisclosureAgreementValidator {
        return DisclosureAgreementValidator(
            rules: [
                DisclosureAgreementCodePrefixRule(prefix: "OPS"),
                DisclosureAgreementAllowedCodeRule(allowed: ["rolling", "fallback"]),
                DisclosureAgreementRequiredLocaleRule(message: "disclosure agreement needs a value"),
                DisclosureAgreementCreatedAtRangeRule(min: 1000, max: 86400),
                DisclosureAgreementTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
