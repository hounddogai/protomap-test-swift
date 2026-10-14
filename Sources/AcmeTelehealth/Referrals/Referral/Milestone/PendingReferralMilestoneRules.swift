import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending referral milestone must pass. Check returns its problems, or none.
    protocol PendingReferralMilestoneRule {
        func check(_ item: PendingReferralMilestone) -> [String]
    }

    final class PendingReferralMilestoneMinimumRangeRule: PendingReferralMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingReferralMilestone) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingReferralMilestoneUnitLengthRule: PendingReferralMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferralMilestone) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReferralMilestoneAllowedUnitRule: PendingReferralMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingReferralMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is unknown"]
            }
            return []
        }
    }

    final class PendingReferralMilestoneRequiredNameRule: PendingReferralMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferralMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferralMilestoneCodeLengthRule: PendingReferralMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferralMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending referral milestone.
    final class PendingReferralMilestoneValidator {
        var rules: [any PendingReferralMilestoneRule]

        init(rules: [any PendingReferralMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReferralMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingReferralMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReferralMilestone]) -> [String: [String]] {
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

    static func defaultPendingReferralMilestoneValidator() -> PendingReferralMilestoneValidator {
        return PendingReferralMilestoneValidator(
            rules: [
                PendingReferralMilestoneMinimumRangeRule(min: 3.7, max: 3543.4),
                PendingReferralMilestoneUnitLengthRule(maxLength: 255),
                PendingReferralMilestoneAllowedUnitRule(allowed: []),
                PendingReferralMilestoneRequiredNameRule(message: "pending referral milestone needs an entry"),
                PendingReferralMilestoneCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
