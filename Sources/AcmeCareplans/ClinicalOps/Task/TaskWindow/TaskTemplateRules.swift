import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task template must pass. Check returns its problems, or none.
    protocol TaskTemplateRule {
        func check(_ item: TaskTemplate) -> [String]
    }

    final class TaskTemplateRequiredNameRule: TaskTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskTemplate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskTemplateQuantityRangeRule: TaskTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskTemplate) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskTemplateAllowedCodeRule: TaskTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class TaskTemplateLabelLengthRule: TaskTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskTemplateAttemptsRangeRule: TaskTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskTemplate) -> [String] {
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

    final class TaskTemplateRequiredCodeRule: TaskTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task template.
    final class TaskTemplateValidator {
        var rules: [any TaskTemplateRule]

        init(rules: [any TaskTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskTemplate]) -> [String: [String]] {
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

    static func defaultTaskTemplateValidator() -> TaskTemplateValidator {
        return TaskTemplateValidator(
            rules: [
                TaskTemplateRequiredNameRule(message: "task template needs a value"),
                TaskTemplateQuantityRangeRule(min: 80, max: 3600),
                TaskTemplateAllowedCodeRule(allowed: ["batched"]),
                TaskTemplateLabelLengthRule(maxLength: 80),
                TaskTemplateAttemptsRangeRule(min: 255, max: 1000),
                TaskTemplateRequiredCodeRule(message: "task template needs an entry"),
            ]
        )
    }
}
