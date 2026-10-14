import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback risk score rule must pass. Check returns its problems, or none.
    protocol FallbackRiskScoreRuleRule {
        func check(_ item: FallbackRiskScoreRule) -> [String]
    }

    final class FallbackRiskScoreRuleCodePrefixRule: FallbackRiskScoreRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackRiskScoreRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackRiskScoreRuleLabelLengthRule: FallbackRiskScoreRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRiskScoreRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRiskScoreRuleQuantityRangeRule: FallbackRiskScoreRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRiskScoreRule) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackRiskScoreRuleAllowedCodeRule: FallbackRiskScoreRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackRiskScoreRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class FallbackRiskScoreRuleRequiredCodeRule: FallbackRiskScoreRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRiskScoreRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback risk score rule.
    final class FallbackRiskScoreRuleValidator {
        var rules: [any FallbackRiskScoreRuleRule]

        init(rules: [any FallbackRiskScoreRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRiskScoreRule) -> [String] {
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

        func requireValid(_ item: FallbackRiskScoreRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRiskScoreRule]) -> [String: [String]] {
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

    static func defaultFallbackRiskScoreRuleValidator() -> FallbackRiskScoreRuleValidator {
        return FallbackRiskScoreRuleValidator(
            rules: [
                FallbackRiskScoreRuleCodePrefixRule(prefix: "ACM"),
                FallbackRiskScoreRuleLabelLengthRule(maxLength: 1000),
                FallbackRiskScoreRuleQuantityRangeRule(min: 255, max: 86400),
                FallbackRiskScoreRuleAllowedCodeRule(allowed: ["legacy"]),
                FallbackRiskScoreRuleRequiredCodeRule(message: "fallback risk score rule needs an entry"),
            ]
        )
    }
}
