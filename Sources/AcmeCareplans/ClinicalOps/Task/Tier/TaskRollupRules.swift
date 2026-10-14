import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task rollup must pass. Check returns its problems, or none.
    protocol TaskRollupRule {
        func check(_ item: TaskRollup) -> [String]
    }

    final class TaskRollupPhoneLengthRule: TaskRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskRollup) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskRollupCodeLengthRule: TaskRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskRollupDosageMgRangeRule: TaskRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskRollup) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskRollupRequiredCodeRule: TaskRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskRollupAllowedCodeRule: TaskRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a task rollup.
    final class TaskRollupValidator {
        var rules: [any TaskRollupRule]

        init(rules: [any TaskRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskRollup]) -> [String: [String]] {
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

    static func defaultTaskRollupValidator() -> TaskRollupValidator {
        return TaskRollupValidator(
            rules: [
                TaskRollupPhoneLengthRule(maxLength: 32),
                TaskRollupCodeLengthRule(maxLength: 120),
                TaskRollupDosageMgRangeRule(min: 7.6, max: 2697.8),
                TaskRollupRequiredCodeRule(message: "task rollup needs this field"),
                TaskRollupAllowedCodeRule(allowed: ["weighted", "scheduled", "regional"]),
            ]
        )
    }
}
