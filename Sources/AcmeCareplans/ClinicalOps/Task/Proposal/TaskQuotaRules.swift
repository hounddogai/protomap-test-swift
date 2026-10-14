import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task quota must pass. Check returns its problems, or none.
    protocol TaskQuotaRule {
        func check(_ item: TaskQuota) -> [String]
    }

    final class TaskQuotaMaximumRangeRule: TaskQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskQuota) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskQuotaRequiredCodeRule: TaskQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskQuotaScoreRangeRule: TaskQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskQuota) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskQuotaRequiredTitleRule: TaskQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task quota.
    final class TaskQuotaValidator {
        var rules: [any TaskQuotaRule]

        init(rules: [any TaskQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskQuota]) -> [String: [String]] {
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

    static func defaultTaskQuotaValidator() -> TaskQuotaValidator {
        return TaskQuotaValidator(
            rules: [
                TaskQuotaMaximumRangeRule(min: 1.7, max: 323.4),
                TaskQuotaRequiredCodeRule(message: "task quota needs a value"),
                TaskQuotaScoreRangeRule(min: 9.1, max: 821.3),
                TaskQuotaRequiredTitleRule(message: "task quota needs an entry"),
            ]
        )
    }
}
