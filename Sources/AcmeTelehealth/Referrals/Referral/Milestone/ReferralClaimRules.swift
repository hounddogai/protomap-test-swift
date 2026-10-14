import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral claim must pass. Check returns its problems, or none.
    protocol ReferralClaimRule {
        func check(_ item: ReferralClaim) -> [String]
    }

    final class ReferralClaimRequiredChannelRule: ReferralClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralClaim) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralClaimCodeLengthRule: ReferralClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralClaimCreatedAtRangeRule: ReferralClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralClaim) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralClaimArchivedGuardRule: ReferralClaimRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ReferralClaim) -> [String] {
            if item.archived && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a referral claim.
    final class ReferralClaimValidator {
        var rules: [any ReferralClaimRule]

        init(rules: [any ReferralClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralClaim]) -> [String: [String]] {
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

    static func defaultReferralClaimValidator() -> ReferralClaimValidator {
        return ReferralClaimValidator(
            rules: [
                ReferralClaimRequiredChannelRule(message: "referral claim needs an entry"),
                ReferralClaimCodeLengthRule(maxLength: 16),
                ReferralClaimCreatedAtRangeRule(min: 3600, max: 3600),
                ReferralClaimArchivedGuardRule(limit: 32),
            ]
        )
    }
}
