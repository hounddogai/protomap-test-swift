import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict worklist plan must pass. Check returns its problems, or none.
    protocol StrictWorklistPlanRule {
        func check(_ item: StrictWorklistPlan) -> [String]
    }

    final class StrictWorklistPlanTitleLengthRule: StrictWorklistPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWorklistPlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictWorklistPlanPriorityRangeRule: StrictWorklistPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictWorklistPlan) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictWorklistPlanRequiredWardRule: StrictWorklistPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWorklistPlan) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWorklistPlanVisibleGuardRule: StrictWorklistPlanRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: StrictWorklistPlan) -> [String] {
            if item.visible && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class StrictWorklistPlanWardLengthRule: StrictWorklistPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWorklistPlan) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict worklist plan.
    final class StrictWorklistPlanValidator {
        var rules: [any StrictWorklistPlanRule]

        init(rules: [any StrictWorklistPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictWorklistPlan) -> [String] {
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

        func requireValid(_ item: StrictWorklistPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictWorklistPlan]) -> [String: [String]] {
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

    static func defaultStrictWorklistPlanValidator() -> StrictWorklistPlanValidator {
        return StrictWorklistPlanValidator(
            rules: [
                StrictWorklistPlanTitleLengthRule(maxLength: 1000),
                StrictWorklistPlanPriorityRangeRule(min: 64, max: 64),
                StrictWorklistPlanRequiredWardRule(message: "strict worklist plan needs an entry"),
                StrictWorklistPlanVisibleGuardRule(limit: 6.7),
                StrictWorklistPlanWardLengthRule(maxLength: 3600),
            ]
        )
    }
}
