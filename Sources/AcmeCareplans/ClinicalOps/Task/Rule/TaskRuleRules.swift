import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task rule must pass. Check returns its problems, or none.
    protocol TaskRuleRule {
        func check(_ item: TaskRule) -> [String]
    }

    final class TaskRuleRequiredLabelRule: TaskRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskRule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskRuleCeilingRangeRule: TaskRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskRule) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskRuleRequiredReviewerRule: TaskRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskRule) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskRuleCodePrefixRule: TaskRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskRuleRequiredCodeRule: TaskRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task rule.
    final class TaskRuleValidator {
        var rules: [any TaskRuleRule]

        init(rules: [any TaskRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskRule) -> [String] {
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

        func requireValid(_ item: TaskRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskRule]) -> [String: [String]] {
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

    static func defaultTaskRuleValidator() -> TaskRuleValidator {
        return TaskRuleValidator(
            rules: [
                TaskRuleRequiredLabelRule(message: "task rule needs an entry"),
                TaskRuleCeilingRangeRule(min: 2.4, max: 4164.4),
                TaskRuleRequiredReviewerRule(message: "task rule needs an entry"),
                TaskRuleCodePrefixRule(prefix: "REF"),
                TaskRuleRequiredCodeRule(message: "task rule needs a value"),
            ]
        )
    }
}
