import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task tier must pass. Check returns its problems, or none.
    protocol TaskTierRule {
        func check(_ item: TaskTier) -> [String]
    }

    final class TaskTierAllowedCodeRule: TaskTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class TaskTierNameLengthRule: TaskTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskTierRequiredOwnerIDRule: TaskTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskTier) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskTierRequiredNameRule: TaskTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskTierRequiredCodeRule: TaskTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task tier.
    final class TaskTierValidator {
        var rules: [any TaskTierRule]

        init(rules: [any TaskTierRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskTier) -> [String] {
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

        func requireValid(_ item: TaskTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskTier]) -> [String: [String]] {
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

    static func defaultTaskTierValidator() -> TaskTierValidator {
        return TaskTierValidator(
            rules: [
                TaskTierAllowedCodeRule(allowed: ["capped"]),
                TaskTierNameLengthRule(maxLength: 64),
                TaskTierRequiredOwnerIDRule(message: "task tier needs this field"),
                TaskTierRequiredNameRule(message: "task tier needs an entry"),
                TaskTierRequiredCodeRule(message: "task tier needs a value"),
            ]
        )
    }
}
