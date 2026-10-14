import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral plan must pass. Check returns its problems, or none.
    protocol ReferralPlanRule {
        func check(_ item: ReferralPlan) -> [String]
    }

    final class ReferralPlanApprovedGuardRule: ReferralPlanRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ReferralPlan) -> [String] {
            if item.approved && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ReferralPlanOwnerIDLengthRule: ReferralPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralPlan) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralPlanGraceDaysRangeRule: ReferralPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralPlan) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralPlanRequiredOwnerIDRule: ReferralPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralPlan) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralPlanTitleLengthRule: ReferralPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralPlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralPlanRevisionRangeRule: ReferralPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralPlan) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a referral plan.
    final class ReferralPlanValidator {
        var rules: [any ReferralPlanRule]

        init(rules: [any ReferralPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralPlan) -> [String] {
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

        func requireValid(_ item: ReferralPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralPlan]) -> [String: [String]] {
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

    static func defaultReferralPlanValidator() -> ReferralPlanValidator {
        return ReferralPlanValidator(
            rules: [
                ReferralPlanApprovedGuardRule(limit: 32),
                ReferralPlanOwnerIDLengthRule(maxLength: 255),
                ReferralPlanGraceDaysRangeRule(min: 255, max: 1000),
                ReferralPlanRequiredOwnerIDRule(message: "referral plan needs a value"),
                ReferralPlanTitleLengthRule(maxLength: 86400),
                ReferralPlanRevisionRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
