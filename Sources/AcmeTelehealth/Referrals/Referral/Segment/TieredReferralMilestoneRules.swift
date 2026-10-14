import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered referral milestone must pass. Check returns its problems, or none.
    protocol TieredReferralMilestoneRule {
        func check(_ item: TieredReferralMilestone) -> [String]
    }

    final class TieredReferralMilestoneRequiredCodeRule: TieredReferralMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferralMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferralMilestoneTitleLengthRule: TieredReferralMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferralMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferralMilestoneRequiredExternalRefRule: TieredReferralMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferralMilestone) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferralMilestoneScoreRangeRule: TieredReferralMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReferralMilestone) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredReferralMilestoneCodePrefixRule: TieredReferralMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredReferralMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered referral milestone.
    final class TieredReferralMilestoneValidator {
        var rules: [any TieredReferralMilestoneRule]

        init(rules: [any TieredReferralMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReferralMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredReferralMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReferralMilestone]) -> [String: [String]] {
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

    static func defaultTieredReferralMilestoneValidator() -> TieredReferralMilestoneValidator {
        return TieredReferralMilestoneValidator(
            rules: [
                TieredReferralMilestoneRequiredCodeRule(message: "tiered referral milestone needs an entry"),
                TieredReferralMilestoneTitleLengthRule(maxLength: 80),
                TieredReferralMilestoneRequiredExternalRefRule(message: "tiered referral milestone needs a value"),
                TieredReferralMilestoneScoreRangeRule(min: 1.6, max: 3471.3),
                TieredReferralMilestoneCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
