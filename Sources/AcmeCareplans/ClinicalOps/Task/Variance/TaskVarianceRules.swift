import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task variance must pass. Check returns its problems, or none.
    protocol TaskVarianceRule {
        func check(_ item: TaskVariance) -> [String]
    }

    final class TaskVarianceCodePrefixRule: TaskVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskVarianceRequiredBedRule: TaskVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskVariance) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskVarianceCodeLengthRule: TaskVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task variance.
    final class TaskVarianceValidator {
        var rules: [any TaskVarianceRule]

        init(rules: [any TaskVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskVariance]) -> [String: [String]] {
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

    static func defaultTaskVarianceValidator() -> TaskVarianceValidator {
        return TaskVarianceValidator(
            rules: [
                TaskVarianceCodePrefixRule(prefix: "ACM"),
                TaskVarianceRequiredBedRule(message: "task variance needs a value"),
                TaskVarianceCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
