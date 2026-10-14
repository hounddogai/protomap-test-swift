import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive referral claim must pass. Check returns its problems, or none.
    protocol AdaptiveReferralClaimRule {
        func check(_ item: AdaptiveReferralClaim) -> [String]
    }

    final class AdaptiveReferralClaimCodeLengthRule: AdaptiveReferralClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReferralClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveReferralClaimRequiredCategoryRule: AdaptiveReferralClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveReferralClaim) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveReferralClaimUnitLengthRule: AdaptiveReferralClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReferralClaim) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveReferralClaimAllowedUnitRule: AdaptiveReferralClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveReferralClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive referral claim.
    final class AdaptiveReferralClaimValidator {
        var rules: [any AdaptiveReferralClaimRule]

        init(rules: [any AdaptiveReferralClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveReferralClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveReferralClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveReferralClaim]) -> [String: [String]] {
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

    static func defaultAdaptiveReferralClaimValidator() -> AdaptiveReferralClaimValidator {
        return AdaptiveReferralClaimValidator(
            rules: [
                AdaptiveReferralClaimCodeLengthRule(maxLength: 3600),
                AdaptiveReferralClaimRequiredCategoryRule(message: "adaptive referral claim needs this field"),
                AdaptiveReferralClaimUnitLengthRule(maxLength: 32),
                AdaptiveReferralClaimAllowedUnitRule(allowed: ["seasonal", "scheduled", "rolling"]),
            ]
        )
    }
}
