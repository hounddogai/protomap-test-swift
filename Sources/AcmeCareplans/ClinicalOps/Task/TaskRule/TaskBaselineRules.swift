import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task baseline must pass. Check returns its problems, or none.
    protocol TaskBaselineRule {
        func check(_ item: TaskBaseline) -> [String]
    }

    final class TaskBaselineScoreRangeRule: TaskBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskBaseline) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskBaselineCostRangeRule: TaskBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskBaseline) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskBaselineCodeLengthRule: TaskBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task baseline.
    final class TaskBaselineValidator {
        var rules: [any TaskBaselineRule]

        init(rules: [any TaskBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskBaseline) -> [String] {
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

        func requireValid(_ item: TaskBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskBaseline]) -> [String: [String]] {
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

    static func defaultTaskBaselineValidator() -> TaskBaselineValidator {
        return TaskBaselineValidator(
            rules: [
                TaskBaselineScoreRangeRule(min: 4.7, max: 3944.4),
                TaskBaselineCostRangeRule(min: 3.2, max: 2047.5),
                TaskBaselineCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
