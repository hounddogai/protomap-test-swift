import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral template must pass. Check returns its problems, or none.
    protocol ReferralTemplateRule {
        func check(_ item: ReferralTemplate) -> [String]
    }

    final class ReferralTemplateCodeLengthRule: ReferralTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralTemplateAllowedLabelRule: ReferralTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class ReferralTemplateRequiredTitleRule: ReferralTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralTemplateCodePrefixRule: ReferralTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferralTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferralTemplateLabelLengthRule: ReferralTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral template.
    final class ReferralTemplateValidator {
        var rules: [any ReferralTemplateRule]

        init(rules: [any ReferralTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralTemplate]) -> [String: [String]] {
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

    static func defaultReferralTemplateValidator() -> ReferralTemplateValidator {
        return ReferralTemplateValidator(
            rules: [
                ReferralTemplateCodeLengthRule(maxLength: 255),
                ReferralTemplateAllowedLabelRule(allowed: ["batched", "scheduled"]),
                ReferralTemplateRequiredTitleRule(message: "referral template needs this field"),
                ReferralTemplateCodePrefixRule(prefix: "ACM"),
                ReferralTemplateLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
