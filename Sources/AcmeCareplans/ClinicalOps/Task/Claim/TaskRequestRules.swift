import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task request must pass. Check returns its problems, or none.
    protocol TaskRequestRule {
        func check(_ item: TaskRequest) -> [String]
    }

    final class TaskRequestCodePrefixRule: TaskRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskRequestLabelLengthRule: TaskRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskRequestCostRangeRule: TaskRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskRequest) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a task request.
    final class TaskRequestValidator {
        var rules: [any TaskRequestRule]

        init(rules: [any TaskRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskRequest]) -> [String: [String]] {
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

    static func defaultTaskRequestValidator() -> TaskRequestValidator {
        return TaskRequestValidator(
            rules: [
                TaskRequestCodePrefixRule(prefix: "X"),
                TaskRequestLabelLengthRule(maxLength: 120),
                TaskRequestCostRangeRule(min: 9.1, max: 1173.1),
            ]
        )
    }
}
