import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional consent form rule must pass. Check returns its problems, or none.
    protocol RegionalConsentFormRuleRule {
        func check(_ item: RegionalConsentFormRule) -> [String]
    }

    final class RegionalConsentFormRuleRequiredLocaleRule: RegionalConsentFormRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalConsentFormRule) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalConsentFormRuleCodeLengthRule: RegionalConsentFormRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalConsentFormRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalConsentFormRuleCodePrefixRule: RegionalConsentFormRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalConsentFormRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional consent form rule.
    final class RegionalConsentFormRuleValidator {
        var rules: [any RegionalConsentFormRuleRule]

        init(rules: [any RegionalConsentFormRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalConsentFormRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalConsentFormRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalConsentFormRule]) -> [String: [String]] {
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

    static func defaultRegionalConsentFormRuleValidator() -> RegionalConsentFormRuleValidator {
        return RegionalConsentFormRuleValidator(
            rules: [
                RegionalConsentFormRuleRequiredLocaleRule(message: "regional consent form rule needs a value"),
                RegionalConsentFormRuleCodeLengthRule(maxLength: 32),
                RegionalConsentFormRuleCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
