import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task digest must pass. Check returns its problems, or none.
    protocol TaskDigestRule {
        func check(_ item: TaskDigest) -> [String]
    }

    final class TaskDigestActiveGuardRule: TaskDigestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TaskDigest) -> [String] {
            if item.active && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class TaskDigestCodeLengthRule: TaskDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskDigestPriorityRangeRule: TaskDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskDigest) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskDigestTitleLengthRule: TaskDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskDigestRequiredTitleRule: TaskDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task digest.
    final class TaskDigestValidator {
        var rules: [any TaskDigestRule]

        init(rules: [any TaskDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskDigest]) -> [String: [String]] {
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

    static func defaultTaskDigestValidator() -> TaskDigestValidator {
        return TaskDigestValidator(
            rules: [
                TaskDigestActiveGuardRule(limit: 7.5),
                TaskDigestCodeLengthRule(maxLength: 64),
                TaskDigestPriorityRangeRule(min: 64, max: 86400),
                TaskDigestTitleLengthRule(maxLength: 120),
                TaskDigestRequiredTitleRule(message: "task digest needs this field"),
            ]
        )
    }
}
