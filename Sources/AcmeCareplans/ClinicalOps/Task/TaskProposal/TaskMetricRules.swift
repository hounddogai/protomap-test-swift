import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task metric must pass. Check returns its problems, or none.
    protocol TaskMetricRule {
        func check(_ item: TaskMetric) -> [String]
    }

    final class TaskMetricTitleLengthRule: TaskMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskMetricMinimumRangeRule: TaskMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskMetric) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskMetricRequiredTitleRule: TaskMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskMetricCodePrefixRule: TaskMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskMetricRequiredLocaleRule: TaskMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskMetric) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskMetricCodeLengthRule: TaskMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task metric.
    final class TaskMetricValidator {
        var rules: [any TaskMetricRule]

        init(rules: [any TaskMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskMetric]) -> [String: [String]] {
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

    static func defaultTaskMetricValidator() -> TaskMetricValidator {
        return TaskMetricValidator(
            rules: [
                TaskMetricTitleLengthRule(maxLength: 255),
                TaskMetricMinimumRangeRule(min: 7.7, max: 4264.6),
                TaskMetricRequiredTitleRule(message: "task metric needs a value"),
                TaskMetricCodePrefixRule(prefix: "Q"),
                TaskMetricRequiredLocaleRule(message: "task metric needs this field"),
                TaskMetricCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
