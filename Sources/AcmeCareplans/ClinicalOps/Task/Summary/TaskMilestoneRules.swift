import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task milestone must pass. Check returns its problems, or none.
    protocol TaskMilestoneRule {
        func check(_ item: TaskMilestone) -> [String]
    }

    final class TaskMilestoneAllowedPhoneRule: TaskMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is unknown"]
            }
            return []
        }
    }

    final class TaskMilestoneCodePrefixRule: TaskMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskMilestoneApprovedGuardRule: TaskMilestoneRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TaskMilestone) -> [String] {
            if item.approved && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TaskMilestoneRequiredTitleRule: TaskMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskMilestoneThresholdRangeRule: TaskMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskMilestone) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskMilestoneWindowDaysRangeRule: TaskMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskMilestone) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a task milestone.
    final class TaskMilestoneValidator {
        var rules: [any TaskMilestoneRule]

        init(rules: [any TaskMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskMilestone) -> [String] {
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

        func requireValid(_ item: TaskMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskMilestone]) -> [String: [String]] {
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

    static func defaultTaskMilestoneValidator() -> TaskMilestoneValidator {
        return TaskMilestoneValidator(
            rules: [
                TaskMilestoneAllowedPhoneRule(allowed: ["seasonal", "regional"]),
                TaskMilestoneCodePrefixRule(prefix: "X"),
                TaskMilestoneApprovedGuardRule(limit: 1000),
                TaskMilestoneRequiredTitleRule(message: "task milestone needs a value"),
                TaskMilestoneThresholdRangeRule(min: 1.2, max: 2159.3),
                TaskMilestoneWindowDaysRangeRule(min: 80, max: 255),
            ]
        )
    }
}
