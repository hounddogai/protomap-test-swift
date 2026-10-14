import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task cycle must pass. Check returns its problems, or none.
    protocol TaskCycleRule {
        func check(_ item: TaskCycle) -> [String]
    }

    final class TaskCycleAttemptsRangeRule: TaskCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskCycle) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskCycleActiveGuardRule: TaskCycleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TaskCycle) -> [String] {
            if item.active && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class TaskCycleRequiredNameRule: TaskCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskCycleRequiredWardRule: TaskCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskCycle) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskCycleWardLengthRule: TaskCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskCycle) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task cycle.
    final class TaskCycleValidator {
        var rules: [any TaskCycleRule]

        init(rules: [any TaskCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskCycle]) -> [String: [String]] {
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

    static func defaultTaskCycleValidator() -> TaskCycleValidator {
        return TaskCycleValidator(
            rules: [
                TaskCycleAttemptsRangeRule(min: 120, max: 1000),
                TaskCycleActiveGuardRule(limit: 255),
                TaskCycleRequiredNameRule(message: "task cycle needs an entry"),
                TaskCycleRequiredWardRule(message: "task cycle needs an entry"),
                TaskCycleWardLengthRule(maxLength: 86400),
            ]
        )
    }
}
