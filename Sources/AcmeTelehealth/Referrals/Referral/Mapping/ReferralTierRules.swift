import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral tier must pass. Check returns its problems, or none.
    protocol ReferralTierRule {
        func check(_ item: ReferralTier) -> [String]
    }

    final class ReferralTierSummaryLengthRule: ReferralTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralTier) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralTierNameLengthRule: ReferralTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralTierCodePrefixRule: ReferralTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferralTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferralTierRequiredCodeRule: ReferralTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralTierRequiredNameRule: ReferralTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral tier.
    final class ReferralTierValidator {
        var rules: [any ReferralTierRule]

        init(rules: [any ReferralTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralTier]) -> [String: [String]] {
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

    static func defaultReferralTierValidator() -> ReferralTierValidator {
        return ReferralTierValidator(
            rules: [
                ReferralTierSummaryLengthRule(maxLength: 3600),
                ReferralTierNameLengthRule(maxLength: 1000),
                ReferralTierCodePrefixRule(prefix: "REF"),
                ReferralTierRequiredCodeRule(message: "referral tier needs a value"),
                ReferralTierRequiredNameRule(message: "referral tier needs a value"),
            ]
        )
    }
}
