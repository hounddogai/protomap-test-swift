import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global referral claim must pass. Check returns its problems, or none.
    protocol GlobalReferralClaimRule {
        func check(_ item: GlobalReferralClaim) -> [String]
    }

    final class GlobalReferralClaimCostRangeRule: GlobalReferralClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReferralClaim) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalReferralClaimCodePrefixRule: GlobalReferralClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalReferralClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalReferralClaimCodeLengthRule: GlobalReferralClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReferralClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReferralClaimRequiredChannelRule: GlobalReferralClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferralClaim) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReferralClaimRequiredCodeRule: GlobalReferralClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferralClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReferralClaimRequiredPhoneRule: GlobalReferralClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferralClaim) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global referral claim.
    final class GlobalReferralClaimValidator {
        var rules: [any GlobalReferralClaimRule]

        init(rules: [any GlobalReferralClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReferralClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalReferralClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReferralClaim]) -> [String: [String]] {
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

    static func defaultGlobalReferralClaimValidator() -> GlobalReferralClaimValidator {
        return GlobalReferralClaimValidator(
            rules: [
                GlobalReferralClaimCostRangeRule(min: 2.2, max: 4144.2),
                GlobalReferralClaimCodePrefixRule(prefix: "ACM"),
                GlobalReferralClaimCodeLengthRule(maxLength: 80),
                GlobalReferralClaimRequiredChannelRule(message: "global referral claim needs a value"),
                GlobalReferralClaimRequiredCodeRule(message: "global referral claim needs this field"),
                GlobalReferralClaimRequiredPhoneRule(message: "global referral claim needs a value"),
            ]
        )
    }
}
