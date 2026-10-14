import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task plan must pass. Check returns its problems, or none.
    protocol TaskPlanRule {
        func check(_ item: TaskPlan) -> [String]
    }

    final class TaskPlanApprovedGuardRule: TaskPlanRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TaskPlan) -> [String] {
            if item.approved && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TaskPlanDurationMinutesRangeRule: TaskPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskPlan) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskPlanSequenceRangeRule: TaskPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskPlan) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskPlanAllowedLabelRule: TaskPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class TaskPlanCodeLengthRule: TaskPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskPlanCodePrefixRule: TaskPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a task plan.
    final class TaskPlanValidator {
        var rules: [any TaskPlanRule]

        init(rules: [any TaskPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskPlan]) -> [String: [String]] {
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

    static func defaultTaskPlanValidator() -> TaskPlanValidator {
        return TaskPlanValidator(
            rules: [
                TaskPlanApprovedGuardRule(limit: 255),
                TaskPlanDurationMinutesRangeRule(min: 255, max: 3600),
                TaskPlanSequenceRangeRule(min: 80, max: 255),
                TaskPlanAllowedLabelRule(allowed: ["capped"]),
                TaskPlanCodeLengthRule(maxLength: 64),
                TaskPlanCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
