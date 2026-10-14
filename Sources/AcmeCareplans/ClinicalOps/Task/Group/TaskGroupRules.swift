import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task group must pass. Check returns its problems, or none.
    protocol TaskGroupRule {
        func check(_ item: TaskGroup) -> [String]
    }

    final class TaskGroupRequiredTitleRule: TaskGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskGroupCodePrefixRule: TaskGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskGroupCodeLengthRule: TaskGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task group.
    final class TaskGroupValidator {
        var rules: [any TaskGroupRule]

        init(rules: [any TaskGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskGroup]) -> [String: [String]] {
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

    static func defaultTaskGroupValidator() -> TaskGroupValidator {
        return TaskGroupValidator(
            rules: [
                TaskGroupRequiredTitleRule(message: "task group needs this field"),
                TaskGroupCodePrefixRule(prefix: "REF"),
                TaskGroupCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
