import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy referral claim must pass. Check returns its problems, or none.
    protocol LegacyReferralClaimRule {
        func check(_ item: LegacyReferralClaim) -> [String]
    }

    final class LegacyReferralClaimRequiredNameRule: LegacyReferralClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferralClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferralClaimTagsLimitRule: LegacyReferralClaimRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: LegacyReferralClaim) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class LegacyReferralClaimBedLengthRule: LegacyReferralClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferralClaim) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy referral claim.
    final class LegacyReferralClaimValidator {
        var rules: [any LegacyReferralClaimRule]

        init(rules: [any LegacyReferralClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyReferralClaim) -> [String] {
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

        func requireValid(_ item: LegacyReferralClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyReferralClaim]) -> [String: [String]] {
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

    static func defaultLegacyReferralClaimValidator() -> LegacyReferralClaimValidator {
        return LegacyReferralClaimValidator(
            rules: [
                LegacyReferralClaimRequiredNameRule(message: "legacy referral claim needs an entry"),
                LegacyReferralClaimTagsLimitRule(maxCount: 64, banned: ["lenient"]),
                LegacyReferralClaimBedLengthRule(maxLength: 3600),
            ]
        )
    }
}
