import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped consent form rule must pass. Check returns its problems, or none.
    protocol CappedConsentFormRuleRule {
        func check(_ item: CappedConsentFormRule) -> [String]
    }

    final class CappedConsentFormRuleRequiredCodeRule: CappedConsentFormRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedConsentFormRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedConsentFormRuleNameLengthRule: CappedConsentFormRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedConsentFormRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedConsentFormRuleCodeLengthRule: CappedConsentFormRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedConsentFormRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedConsentFormRuleThresholdRangeRule: CappedConsentFormRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedConsentFormRule) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedConsentFormRuleAllowedPayerRule: CappedConsentFormRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedConsentFormRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a capped consent form rule.
    final class CappedConsentFormRuleValidator {
        var rules: [any CappedConsentFormRuleRule]

        init(rules: [any CappedConsentFormRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedConsentFormRule) -> [String] {
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

        func requireValid(_ item: CappedConsentFormRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedConsentFormRule]) -> [String: [String]] {
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

    static func defaultCappedConsentFormRuleValidator() -> CappedConsentFormRuleValidator {
        return CappedConsentFormRuleValidator(
            rules: [
                CappedConsentFormRuleRequiredCodeRule(message: "capped consent form rule needs a value"),
                CappedConsentFormRuleNameLengthRule(maxLength: 16),
                CappedConsentFormRuleCodeLengthRule(maxLength: 80),
                CappedConsentFormRuleThresholdRangeRule(min: 9.4, max: 1059.6),
                CappedConsentFormRuleAllowedPayerRule(allowed: ["strict"]),
            ]
        )
    }
}
