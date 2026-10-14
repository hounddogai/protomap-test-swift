import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up plan must pass. Check returns its problems, or none.
    protocol FollowUpPlanRule {
        func check(_ item: FollowUpPlan) -> [String]
    }

    final class FollowUpPlanNameLengthRule: FollowUpPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpPlan) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpPlanCodeLengthRule: FollowUpPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpPlanRequiredNameRule: FollowUpPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up plan.
    final class FollowUpPlanValidator {
        var rules: [any FollowUpPlanRule]

        init(rules: [any FollowUpPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpPlan) -> [String] {
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

        func requireValid(_ item: FollowUpPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpPlan]) -> [String: [String]] {
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

    static func defaultFollowUpPlanValidator() -> FollowUpPlanValidator {
        return FollowUpPlanValidator(
            rules: [
                FollowUpPlanNameLengthRule(maxLength: 64),
                FollowUpPlanCodeLengthRule(maxLength: 16),
                FollowUpPlanRequiredNameRule(message: "follow up plan needs a value"),
            ]
        )
    }
}
