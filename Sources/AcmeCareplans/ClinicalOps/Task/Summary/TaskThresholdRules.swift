import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task threshold must pass. Check returns its problems, or none.
    protocol TaskThresholdRule {
        func check(_ item: TaskThreshold) -> [String]
    }

    final class TaskThresholdRequiredSourceRule: TaskThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskThreshold) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskThresholdBedLengthRule: TaskThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskThreshold) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskThresholdAllowedSourceRule: TaskThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a task threshold.
    final class TaskThresholdValidator {
        var rules: [any TaskThresholdRule]

        init(rules: [any TaskThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskThreshold) -> [String] {
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

        func requireValid(_ item: TaskThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskThreshold]) -> [String: [String]] {
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

    static func defaultTaskThresholdValidator() -> TaskThresholdValidator {
        return TaskThresholdValidator(
            rules: [
                TaskThresholdRequiredSourceRule(message: "task threshold needs a value"),
                TaskThresholdBedLengthRule(maxLength: 32),
                TaskThresholdAllowedSourceRule(allowed: ["legacy"]),
            ]
        )
    }
}
