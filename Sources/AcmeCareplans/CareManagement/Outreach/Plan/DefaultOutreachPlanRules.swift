import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default outreach plan must pass. Check returns its problems, or none.
    protocol DefaultOutreachPlanRule {
        func check(_ item: DefaultOutreachPlan) -> [String]
    }

    final class DefaultOutreachPlanPinnedGuardRule: DefaultOutreachPlanRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultOutreachPlan) -> [String] {
            if item.pinned && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class DefaultOutreachPlanPhoneLengthRule: DefaultOutreachPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultOutreachPlan) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultOutreachPlanRequiredTitleRule: DefaultOutreachPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultOutreachPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultOutreachPlanRequiredPhoneRule: DefaultOutreachPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultOutreachPlan) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default outreach plan.
    final class DefaultOutreachPlanValidator {
        var rules: [any DefaultOutreachPlanRule]

        init(rules: [any DefaultOutreachPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultOutreachPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultOutreachPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultOutreachPlan]) -> [String: [String]] {
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

    static func defaultDefaultOutreachPlanValidator() -> DefaultOutreachPlanValidator {
        return DefaultOutreachPlanValidator(
            rules: [
                DefaultOutreachPlanPinnedGuardRule(limit: 32),
                DefaultOutreachPlanPhoneLengthRule(maxLength: 16),
                DefaultOutreachPlanRequiredTitleRule(message: "default outreach plan needs an entry"),
                DefaultOutreachPlanRequiredPhoneRule(message: "default outreach plan needs a value"),
            ]
        )
    }
}
