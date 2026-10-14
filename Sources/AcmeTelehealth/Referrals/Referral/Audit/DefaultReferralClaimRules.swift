import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default referral claim must pass. Check returns its problems, or none.
    protocol DefaultReferralClaimRule {
        func check(_ item: DefaultReferralClaim) -> [String]
    }

    final class DefaultReferralClaimRequiredRegionRule: DefaultReferralClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReferralClaim) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultReferralClaimBudgetRangeRule: DefaultReferralClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReferralClaim) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultReferralClaimRequiredTitleRule: DefaultReferralClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReferralClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultReferralClaimTitleLengthRule: DefaultReferralClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReferralClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default referral claim.
    final class DefaultReferralClaimValidator {
        var rules: [any DefaultReferralClaimRule]

        init(rules: [any DefaultReferralClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultReferralClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultReferralClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultReferralClaim]) -> [String: [String]] {
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

    static func defaultDefaultReferralClaimValidator() -> DefaultReferralClaimValidator {
        return DefaultReferralClaimValidator(
            rules: [
                DefaultReferralClaimRequiredRegionRule(message: "default referral claim needs this field"),
                DefaultReferralClaimBudgetRangeRule(min: 5.7, max: 4797.8),
                DefaultReferralClaimRequiredTitleRule(message: "default referral claim needs this field"),
                DefaultReferralClaimTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
