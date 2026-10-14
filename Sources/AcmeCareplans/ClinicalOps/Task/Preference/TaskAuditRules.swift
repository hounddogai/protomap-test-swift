import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task audit must pass. Check returns its problems, or none.
    protocol TaskAuditRule {
        func check(_ item: TaskAudit) -> [String]
    }

    final class TaskAuditAllowedChannelRule: TaskAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is blocked"]
            }
            return []
        }
    }

    final class TaskAuditCodePrefixRule: TaskAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskAuditWardLengthRule: TaskAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskAudit) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskAuditRequiredWardRule: TaskAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskAudit) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task audit.
    final class TaskAuditValidator {
        var rules: [any TaskAuditRule]

        init(rules: [any TaskAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskAudit]) -> [String: [String]] {
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

    static func defaultTaskAuditValidator() -> TaskAuditValidator {
        return TaskAuditValidator(
            rules: [
                TaskAuditAllowedChannelRule(allowed: ["global", "capped", "rolling"]),
                TaskAuditCodePrefixRule(prefix: "ACM"),
                TaskAuditWardLengthRule(maxLength: 80),
                TaskAuditRequiredWardRule(message: "task audit needs this field"),
            ]
        )
    }
}
