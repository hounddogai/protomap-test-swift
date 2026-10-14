import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility claim must pass. Check returns its problems, or none.
    protocol EligibilityClaimRule {
        func check(_ item: EligibilityClaim) -> [String]
    }

    final class EligibilityClaimCodePrefixRule: EligibilityClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityClaimRequiredTitleRule: EligibilityClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityClaimAllowedCodeRule: EligibilityClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class EligibilityClaimRateRangeRule: EligibilityClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityClaim) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a eligibility claim.
    final class EligibilityClaimValidator {
        var rules: [any EligibilityClaimRule]

        init(rules: [any EligibilityClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityClaim]) -> [String: [String]] {
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

    static func defaultEligibilityClaimValidator() -> EligibilityClaimValidator {
        return EligibilityClaimValidator(
            rules: [
                EligibilityClaimCodePrefixRule(prefix: "ACM"),
                EligibilityClaimRequiredTitleRule(message: "eligibility claim needs this field"),
                EligibilityClaimAllowedCodeRule(allowed: ["seasonal", "default", "rolling"]),
                EligibilityClaimRateRangeRule(min: 8.7, max: 4757.7),
            ]
        )
    }
}
