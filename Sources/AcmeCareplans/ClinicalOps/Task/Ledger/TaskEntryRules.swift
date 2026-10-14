import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task entry must pass. Check returns its problems, or none.
    protocol TaskEntryRule {
        func check(_ item: TaskEntry) -> [String]
    }

    final class TaskEntryPriorityRangeRule: TaskEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskEntry) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskEntryRequiredTitleRule: TaskEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskEntryRequiredNameRule: TaskEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task entry.
    final class TaskEntryValidator {
        var rules: [any TaskEntryRule]

        init(rules: [any TaskEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskEntry]) -> [String: [String]] {
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

    static func defaultTaskEntryValidator() -> TaskEntryValidator {
        return TaskEntryValidator(
            rules: [
                TaskEntryPriorityRangeRule(min: 16, max: 3600),
                TaskEntryRequiredTitleRule(message: "task entry needs this field"),
                TaskEntryRequiredNameRule(message: "task entry needs an entry"),
            ]
        )
    }
}
