import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task window must pass. Check returns its problems, or none.
    protocol TaskWindowRule {
        func check(_ item: TaskWindow) -> [String]
    }

    final class TaskWindowQuantityRangeRule: TaskWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskWindow) -> [String] {
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

    final class TaskWindowBudgetRangeRule: TaskWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskWindow) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskWindowAcuityRangeRule: TaskWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskWindow) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskWindowCodePrefixRule: TaskWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskWindowProcedureCodeLengthRule: TaskWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskWindow) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task window.
    final class TaskWindowValidator {
        var rules: [any TaskWindowRule]

        init(rules: [any TaskWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskWindow]) -> [String: [String]] {
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

    static func defaultTaskWindowValidator() -> TaskWindowValidator {
        return TaskWindowValidator(
            rules: [
                TaskWindowQuantityRangeRule(min: 80, max: 1000),
                TaskWindowBudgetRangeRule(min: 5.2, max: 1890.8),
                TaskWindowAcuityRangeRule(min: 120, max: 255),
                TaskWindowCodePrefixRule(prefix: "X"),
                TaskWindowProcedureCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
