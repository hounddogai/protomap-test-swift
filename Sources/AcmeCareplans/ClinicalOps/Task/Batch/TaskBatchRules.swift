import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task batch must pass. Check returns its problems, or none.
    protocol TaskBatchRule {
        func check(_ item: TaskBatch) -> [String]
    }

    final class TaskBatchAllowedEncounterIDRule: TaskBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is inconsistent"]
            }
            return []
        }
    }

    final class TaskBatchNameLengthRule: TaskBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskBatchCodeLengthRule: TaskBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskBatchCodePrefixRule: TaskBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskBatchDescriptionLengthRule: TaskBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskBatch) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskBatchMinimumRangeRule: TaskBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskBatch) -> [String] {
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

    /// Runs every rule of a task batch.
    final class TaskBatchValidator {
        var rules: [any TaskBatchRule]

        init(rules: [any TaskBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskBatch]) -> [String: [String]] {
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

    static func defaultTaskBatchValidator() -> TaskBatchValidator {
        return TaskBatchValidator(
            rules: [
                TaskBatchAllowedEncounterIDRule(allowed: ["seasonal"]),
                TaskBatchNameLengthRule(maxLength: 16),
                TaskBatchCodeLengthRule(maxLength: 64),
                TaskBatchCodePrefixRule(prefix: "REF"),
                TaskBatchDescriptionLengthRule(maxLength: 80),
                TaskBatchMinimumRangeRule(min: 0.7, max: 4490.8),
            ]
        )
    }
}
