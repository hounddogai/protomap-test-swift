import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive follow up policy must pass. Check returns its problems, or none.
    protocol AdaptiveFollowUpPolicyRule {
        func check(_ item: AdaptiveFollowUpPolicy) -> [String]
    }

    final class AdaptiveFollowUpPolicyLabelLengthRule: AdaptiveFollowUpPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFollowUpPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFollowUpPolicyCodePrefixRule: AdaptiveFollowUpPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveFollowUpPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveFollowUpPolicyVisibleGuardRule: AdaptiveFollowUpPolicyRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AdaptiveFollowUpPolicy) -> [String] {
            if item.visible && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class AdaptiveFollowUpPolicyMarginRangeRule: AdaptiveFollowUpPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFollowUpPolicy) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveFollowUpPolicyRequiredLabelRule: AdaptiveFollowUpPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveFollowUpPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveFollowUpPolicyCodeLengthRule: AdaptiveFollowUpPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFollowUpPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive follow up policy.
    final class AdaptiveFollowUpPolicyValidator {
        var rules: [any AdaptiveFollowUpPolicyRule]

        init(rules: [any AdaptiveFollowUpPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFollowUpPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveFollowUpPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFollowUpPolicy]) -> [String: [String]] {
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

    static func defaultAdaptiveFollowUpPolicyValidator() -> AdaptiveFollowUpPolicyValidator {
        return AdaptiveFollowUpPolicyValidator(
            rules: [
                AdaptiveFollowUpPolicyLabelLengthRule(maxLength: 80),
                AdaptiveFollowUpPolicyCodePrefixRule(prefix: "REF"),
                AdaptiveFollowUpPolicyVisibleGuardRule(limit: 3.1),
                AdaptiveFollowUpPolicyMarginRangeRule(min: 5.0, max: 2285.2),
                AdaptiveFollowUpPolicyRequiredLabelRule(message: "adaptive follow up policy needs this field"),
                AdaptiveFollowUpPolicyCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
