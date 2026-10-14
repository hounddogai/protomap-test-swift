import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task slot must pass. Check returns its problems, or none.
    protocol TaskSlotRule {
        func check(_ item: TaskSlot) -> [String]
    }

    final class TaskSlotRequiredNameRule: TaskSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskSlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskSlotRequiredSummaryRule: TaskSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskSlot) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskSlotCodePrefixRule: TaskSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskSlotNameLengthRule: TaskSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskSlotEndsAtRangeRule: TaskSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskSlot) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a task slot.
    final class TaskSlotValidator {
        var rules: [any TaskSlotRule]

        init(rules: [any TaskSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskSlot]) -> [String: [String]] {
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

    static func defaultTaskSlotValidator() -> TaskSlotValidator {
        return TaskSlotValidator(
            rules: [
                TaskSlotRequiredNameRule(message: "task slot needs a value"),
                TaskSlotRequiredSummaryRule(message: "task slot needs this field"),
                TaskSlotCodePrefixRule(prefix: "REF"),
                TaskSlotNameLengthRule(maxLength: 255),
                TaskSlotEndsAtRangeRule(min: 16, max: 32),
            ]
        )
    }
}
