import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task summary must pass. Check returns its problems, or none.
    protocol TaskSummaryRule {
        func check(_ item: TaskSummary) -> [String]
    }

    final class TaskSummaryAllowedCodeRule: TaskSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class TaskSummaryCodeLengthRule: TaskSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskSummaryRequiredNameRule: TaskSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskSummary) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskSummaryCodePrefixRule: TaskSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a task summary.
    final class TaskSummaryValidator {
        var rules: [any TaskSummaryRule]

        init(rules: [any TaskSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskSummary) -> [String] {
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

        func requireValid(_ item: TaskSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskSummary]) -> [String: [String]] {
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

    static func defaultTaskSummaryValidator() -> TaskSummaryValidator {
        return TaskSummaryValidator(
            rules: [
                TaskSummaryAllowedCodeRule(allowed: ["scheduled", "tiered"]),
                TaskSummaryCodeLengthRule(maxLength: 64),
                TaskSummaryRequiredNameRule(message: "task summary needs an entry"),
                TaskSummaryCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
