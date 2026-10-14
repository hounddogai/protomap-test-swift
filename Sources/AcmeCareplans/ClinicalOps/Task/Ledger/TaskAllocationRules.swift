import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task allocation must pass. Check returns its problems, or none.
    protocol TaskAllocationRule {
        func check(_ item: TaskAllocation) -> [String]
    }

    final class TaskAllocationRequiredLocaleRule: TaskAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskAllocation) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskAllocationCodeLengthRule: TaskAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskAllocationRequiredLabelRule: TaskAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskAllocationRequiredEncounterIDRule: TaskAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskAllocation) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskAllocationLocaleLengthRule: TaskAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskAllocation) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskAllocationRatioRangeRule: TaskAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskAllocation) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a task allocation.
    final class TaskAllocationValidator {
        var rules: [any TaskAllocationRule]

        init(rules: [any TaskAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskAllocation) -> [String] {
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

        func requireValid(_ item: TaskAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskAllocation]) -> [String: [String]] {
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

    static func defaultTaskAllocationValidator() -> TaskAllocationValidator {
        return TaskAllocationValidator(
            rules: [
                TaskAllocationRequiredLocaleRule(message: "task allocation needs this field"),
                TaskAllocationCodeLengthRule(maxLength: 3600),
                TaskAllocationRequiredLabelRule(message: "task allocation needs this field"),
                TaskAllocationRequiredEncounterIDRule(message: "task allocation needs an entry"),
                TaskAllocationLocaleLengthRule(maxLength: 80),
                TaskAllocationRatioRangeRule(min: 5.5, max: 3045.1),
            ]
        )
    }
}
