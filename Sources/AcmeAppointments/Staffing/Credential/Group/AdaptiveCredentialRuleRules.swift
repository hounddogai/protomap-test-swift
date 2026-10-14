import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive credential rule must pass. Check returns its problems, or none.
    protocol AdaptiveCredentialRuleRule {
        func check(_ item: AdaptiveCredentialRule) -> [String]
    }

    final class AdaptiveCredentialRuleRequiredLabelRule: AdaptiveCredentialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCredentialRule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCredentialRuleLabelLengthRule: AdaptiveCredentialRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCredentialRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCredentialRuleCodePrefixRule: AdaptiveCredentialRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveCredentialRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive credential rule.
    final class AdaptiveCredentialRuleValidator {
        var rules: [any AdaptiveCredentialRuleRule]

        init(rules: [any AdaptiveCredentialRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCredentialRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveCredentialRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCredentialRule]) -> [String: [String]] {
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

    static func defaultAdaptiveCredentialRuleValidator() -> AdaptiveCredentialRuleValidator {
        return AdaptiveCredentialRuleValidator(
            rules: [
                AdaptiveCredentialRuleRequiredLabelRule(message: "adaptive credential rule needs an entry"),
                AdaptiveCredentialRuleLabelLengthRule(maxLength: 120),
                AdaptiveCredentialRuleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
