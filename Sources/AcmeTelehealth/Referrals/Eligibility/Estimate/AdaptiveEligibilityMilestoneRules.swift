import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive eligibility milestone must pass. Check returns its problems, or none.
    protocol AdaptiveEligibilityMilestoneRule {
        func check(_ item: AdaptiveEligibilityMilestone) -> [String]
    }

    final class AdaptiveEligibilityMilestoneCodePrefixRule: AdaptiveEligibilityMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveEligibilityMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveEligibilityMilestoneAllowedCodeRule: AdaptiveEligibilityMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveEligibilityMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class AdaptiveEligibilityMilestoneCodeLengthRule: AdaptiveEligibilityMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveEligibilityMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveEligibilityMilestoneAllergyLengthRule: AdaptiveEligibilityMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveEligibilityMilestone) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveEligibilityMilestoneRequiredAllergyRule: AdaptiveEligibilityMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveEligibilityMilestone) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive eligibility milestone.
    final class AdaptiveEligibilityMilestoneValidator {
        var rules: [any AdaptiveEligibilityMilestoneRule]

        init(rules: [any AdaptiveEligibilityMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveEligibilityMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveEligibilityMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveEligibilityMilestone]) -> [String: [String]] {
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

    static func defaultAdaptiveEligibilityMilestoneValidator() -> AdaptiveEligibilityMilestoneValidator {
        return AdaptiveEligibilityMilestoneValidator(
            rules: [
                AdaptiveEligibilityMilestoneCodePrefixRule(prefix: "X"),
                AdaptiveEligibilityMilestoneAllowedCodeRule(allowed: ["pending", "lenient", "rolling"]),
                AdaptiveEligibilityMilestoneCodeLengthRule(maxLength: 86400),
                AdaptiveEligibilityMilestoneAllergyLengthRule(maxLength: 80),
                AdaptiveEligibilityMilestoneRequiredAllergyRule(
                    message: "adaptive eligibility milestone needs a value"
                ),
            ]
        )
    }
}
