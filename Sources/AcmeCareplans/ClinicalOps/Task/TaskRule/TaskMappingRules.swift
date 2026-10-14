import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task mapping must pass. Check returns its problems, or none.
    protocol TaskMappingRule {
        func check(_ item: TaskMapping) -> [String]
    }

    final class TaskMappingRefillsRangeRule: TaskMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskMapping) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskMappingCodePrefixRule: TaskMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskMappingNotesLengthRule: TaskMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskMapping) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task mapping.
    final class TaskMappingValidator {
        var rules: [any TaskMappingRule]

        init(rules: [any TaskMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskMapping) -> [String] {
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

        func requireValid(_ item: TaskMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskMapping]) -> [String: [String]] {
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

    static func defaultTaskMappingValidator() -> TaskMappingValidator {
        return TaskMappingValidator(
            rules: [
                TaskMappingRefillsRangeRule(min: 80, max: 3600),
                TaskMappingCodePrefixRule(prefix: "REF"),
                TaskMappingNotesLengthRule(maxLength: 255),
            ]
        )
    }
}
