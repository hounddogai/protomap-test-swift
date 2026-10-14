import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal plan must pass. Check returns its problems, or none.
    protocol GoalPlanRule {
        func check(_ item: GoalPlan) -> [String]
    }

    final class GoalPlanAllowedReviewerRule: GoalPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is not allowed"]
            }
            return []
        }
    }

    final class GoalPlanCodePrefixRule: GoalPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalPlanCapacityRangeRule: GoalPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalPlan) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalPlanRequiredNameRule: GoalPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalPlanCodeLengthRule: GoalPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalPlanVisitMinutesRangeRule: GoalPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalPlan) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a goal plan.
    final class GoalPlanValidator {
        var rules: [any GoalPlanRule]

        init(rules: [any GoalPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalPlan]) -> [String: [String]] {
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

    static func defaultGoalPlanValidator() -> GoalPlanValidator {
        return GoalPlanValidator(
            rules: [
                GoalPlanAllowedReviewerRule(allowed: ["manual", "weighted", "adaptive"]),
                GoalPlanCodePrefixRule(prefix: "REF"),
                GoalPlanCapacityRangeRule(min: 120, max: 255),
                GoalPlanRequiredNameRule(message: "goal plan needs a value"),
                GoalPlanCodeLengthRule(maxLength: 64),
                GoalPlanVisitMinutesRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
