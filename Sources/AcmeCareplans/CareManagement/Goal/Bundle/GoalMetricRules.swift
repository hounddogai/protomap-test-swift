import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal metric must pass. Check returns its problems, or none.
    protocol GoalMetricRule {
        func check(_ item: GoalMetric) -> [String]
    }

    final class GoalMetricRequiredCodeRule: GoalMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalMetricRetriesRangeRule: GoalMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalMetric) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalMetricSpecialtyLengthRule: GoalMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalMetric) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalMetricCodeLengthRule: GoalMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal metric.
    final class GoalMetricValidator {
        var rules: [any GoalMetricRule]

        init(rules: [any GoalMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalMetric]) -> [String: [String]] {
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

    static func defaultGoalMetricValidator() -> GoalMetricValidator {
        return GoalMetricValidator(
            rules: [
                GoalMetricRequiredCodeRule(message: "goal metric needs this field"),
                GoalMetricRetriesRangeRule(min: 32, max: 255),
                GoalMetricSpecialtyLengthRule(maxLength: 32),
                GoalMetricCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
