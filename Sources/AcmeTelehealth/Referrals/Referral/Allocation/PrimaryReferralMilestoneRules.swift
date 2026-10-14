import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary referral milestone must pass. Check returns its problems, or none.
    protocol PrimaryReferralMilestoneRule {
        func check(_ item: PrimaryReferralMilestone) -> [String]
    }

    final class PrimaryReferralMilestoneUpdatedAtRangeRule: PrimaryReferralMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryReferralMilestone) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryReferralMilestoneAllowedCodeRule: PrimaryReferralMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryReferralMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class PrimaryReferralMilestoneRequiredCodeRule: PrimaryReferralMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReferralMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryReferralMilestoneCodeLengthRule: PrimaryReferralMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReferralMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryReferralMilestoneRequiredTitleRule: PrimaryReferralMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReferralMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryReferralMilestoneCodePrefixRule: PrimaryReferralMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryReferralMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary referral milestone.
    final class PrimaryReferralMilestoneValidator {
        var rules: [any PrimaryReferralMilestoneRule]

        init(rules: [any PrimaryReferralMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryReferralMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryReferralMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryReferralMilestone]) -> [String: [String]] {
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

    static func defaultPrimaryReferralMilestoneValidator() -> PrimaryReferralMilestoneValidator {
        return PrimaryReferralMilestoneValidator(
            rules: [
                PrimaryReferralMilestoneUpdatedAtRangeRule(min: 16, max: 80),
                PrimaryReferralMilestoneAllowedCodeRule(allowed: []),
                PrimaryReferralMilestoneRequiredCodeRule(message: "primary referral milestone needs an entry"),
                PrimaryReferralMilestoneCodeLengthRule(maxLength: 64),
                PrimaryReferralMilestoneRequiredTitleRule(message: "primary referral milestone needs a value"),
                PrimaryReferralMilestoneCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
