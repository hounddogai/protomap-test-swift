import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task override must pass. Check returns its problems, or none.
    protocol TaskOverrideRule {
        func check(_ item: TaskOverride) -> [String]
    }

    final class TaskOverrideAllowedTitleRule: TaskOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class TaskOverrideRequiredCodeRule: TaskOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskOverrideTitleLengthRule: TaskOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskOverrideRevisionRangeRule: TaskOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskOverride) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskOverrideRequiredTitleRule: TaskOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task override.
    final class TaskOverrideValidator {
        var rules: [any TaskOverrideRule]

        init(rules: [any TaskOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskOverride]) -> [String: [String]] {
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

    static func defaultTaskOverrideValidator() -> TaskOverrideValidator {
        return TaskOverrideValidator(
            rules: [
                TaskOverrideAllowedTitleRule(allowed: ["primary", "batched", "pending"]),
                TaskOverrideRequiredCodeRule(message: "task override needs this field"),
                TaskOverrideTitleLengthRule(maxLength: 255),
                TaskOverrideRevisionRangeRule(min: 32, max: 120),
                TaskOverrideRequiredTitleRule(message: "task override needs this field"),
            ]
        )
    }
}
