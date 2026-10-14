import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled eligibility plan must pass. Check returns its problems, or none.
    protocol ScheduledEligibilityPlanRule {
        func check(_ item: ScheduledEligibilityPlan) -> [String]
    }

    final class ScheduledEligibilityPlanRequiredLocaleRule: ScheduledEligibilityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledEligibilityPlan) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledEligibilityPlanUpdatedAtRangeRule: ScheduledEligibilityPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledEligibilityPlan) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledEligibilityPlanLimitRangeRule: ScheduledEligibilityPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledEligibilityPlan) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledEligibilityPlanRequiredOwnerIDRule: ScheduledEligibilityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledEligibilityPlan) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled eligibility plan.
    final class ScheduledEligibilityPlanValidator {
        var rules: [any ScheduledEligibilityPlanRule]

        init(rules: [any ScheduledEligibilityPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledEligibilityPlan) -> [String] {
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

        func requireValid(_ item: ScheduledEligibilityPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledEligibilityPlan]) -> [String: [String]] {
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

    static func defaultScheduledEligibilityPlanValidator() -> ScheduledEligibilityPlanValidator {
        return ScheduledEligibilityPlanValidator(
            rules: [
                ScheduledEligibilityPlanRequiredLocaleRule(message: "scheduled eligibility plan needs a value"),
                ScheduledEligibilityPlanUpdatedAtRangeRule(min: 64, max: 80),
                ScheduledEligibilityPlanLimitRangeRule(min: 16, max: 1000),
                ScheduledEligibilityPlanRequiredOwnerIDRule(message: "scheduled eligibility plan needs this field"),
            ]
        )
    }
}
