import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task record must pass. Check returns its problems, or none.
    protocol TaskRecordRule {
        func check(_ item: TaskRecord) -> [String]
    }

    final class TaskRecordCeilingRangeRule: TaskRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskRecord) -> [String] {
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

    final class TaskRecordApprovedGuardRule: TaskRecordRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TaskRecord) -> [String] {
            if item.approved && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TaskRecordRequiredCodeRule: TaskRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskRecordCodePrefixRule: TaskRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskRecordLabelLengthRule: TaskRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task record.
    final class TaskRecordValidator {
        var rules: [any TaskRecordRule]

        init(rules: [any TaskRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskRecord]) -> [String: [String]] {
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

    static func defaultTaskRecordValidator() -> TaskRecordValidator {
        return TaskRecordValidator(
            rules: [
                TaskRecordCeilingRangeRule(min: 9.1, max: 4553.7),
                TaskRecordApprovedGuardRule(limit: 120),
                TaskRecordRequiredCodeRule(message: "task record needs this field"),
                TaskRecordCodePrefixRule(prefix: "Q"),
                TaskRecordLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
