import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback denial rule must pass. Check returns its problems, or none.
    protocol FallbackDenialRuleRule {
        func check(_ item: FallbackDenialRule) -> [String]
    }

    final class FallbackDenialRuleAllowedPhoneRule: FallbackDenialRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackDenialRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is blocked"]
            }
            return []
        }
    }

    final class FallbackDenialRuleWeightRangeRule: FallbackDenialRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDenialRule) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackDenialRuleRequiredCodeRule: FallbackDenialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDenialRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDenialRulePhoneLengthRule: FallbackDenialRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDenialRule) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDenialRuleLabelLengthRule: FallbackDenialRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDenialRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDenialRuleRequiredPhoneRule: FallbackDenialRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDenialRule) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback denial rule.
    final class FallbackDenialRuleValidator {
        var rules: [any FallbackDenialRuleRule]

        init(rules: [any FallbackDenialRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDenialRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackDenialRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDenialRule]) -> [String: [String]] {
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

    static func defaultFallbackDenialRuleValidator() -> FallbackDenialRuleValidator {
        return FallbackDenialRuleValidator(
            rules: [
                FallbackDenialRuleAllowedPhoneRule(allowed: ["primary"]),
                FallbackDenialRuleWeightRangeRule(min: 0.5, max: 4637.6),
                FallbackDenialRuleRequiredCodeRule(message: "fallback denial rule needs an entry"),
                FallbackDenialRulePhoneLengthRule(maxLength: 80),
                FallbackDenialRuleLabelLengthRule(maxLength: 255),
                FallbackDenialRuleRequiredPhoneRule(message: "fallback denial rule needs an entry"),
            ]
        )
    }
}
