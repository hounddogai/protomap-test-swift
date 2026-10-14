import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback consent form policy must pass. Check returns its problems, or none.
    protocol FallbackConsentFormPolicyRule {
        func check(_ item: FallbackConsentFormPolicy) -> [String]
    }

    final class FallbackConsentFormPolicyCurrencyLengthRule: FallbackConsentFormPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackConsentFormPolicy) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackConsentFormPolicyLabelLengthRule: FallbackConsentFormPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackConsentFormPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackConsentFormPolicyCodeLengthRule: FallbackConsentFormPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackConsentFormPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback consent form policy.
    final class FallbackConsentFormPolicyValidator {
        var rules: [any FallbackConsentFormPolicyRule]

        init(rules: [any FallbackConsentFormPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackConsentFormPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackConsentFormPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackConsentFormPolicy]) -> [String: [String]] {
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

    static func defaultFallbackConsentFormPolicyValidator() -> FallbackConsentFormPolicyValidator {
        return FallbackConsentFormPolicyValidator(
            rules: [
                FallbackConsentFormPolicyCurrencyLengthRule(maxLength: 64),
                FallbackConsentFormPolicyLabelLengthRule(maxLength: 86400),
                FallbackConsentFormPolicyCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
