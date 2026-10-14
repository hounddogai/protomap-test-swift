import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task budget must pass. Check returns its problems, or none.
    protocol TaskBudgetRule {
        func check(_ item: TaskBudget) -> [String]
    }

    final class TaskBudgetOwnerIDLengthRule: TaskBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskBudget) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskBudgetGraceDaysRangeRule: TaskBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskBudget) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskBudgetLabelLengthRule: TaskBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskBudget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task budget.
    final class TaskBudgetValidator {
        var rules: [any TaskBudgetRule]

        init(rules: [any TaskBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskBudget]) -> [String: [String]] {
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

    static func defaultTaskBudgetValidator() -> TaskBudgetValidator {
        return TaskBudgetValidator(
            rules: [
                TaskBudgetOwnerIDLengthRule(maxLength: 1000),
                TaskBudgetGraceDaysRangeRule(min: 32, max: 64),
                TaskBudgetLabelLengthRule(maxLength: 1000),
            ]
        )
    }
}
