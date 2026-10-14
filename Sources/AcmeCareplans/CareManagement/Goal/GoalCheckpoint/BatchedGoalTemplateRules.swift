import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched goal template must pass. Check returns its problems, or none.
    protocol BatchedGoalTemplateRule {
        func check(_ item: BatchedGoalTemplate) -> [String]
    }

    final class BatchedGoalTemplateDosageMgRangeRule: BatchedGoalTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedGoalTemplate) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedGoalTemplateGraceDaysRangeRule: BatchedGoalTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedGoalTemplate) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedGoalTemplateBedLengthRule: BatchedGoalTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedGoalTemplate) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedGoalTemplateRequiredCodeRule: BatchedGoalTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedGoalTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched goal template.
    final class BatchedGoalTemplateValidator {
        var rules: [any BatchedGoalTemplateRule]

        init(rules: [any BatchedGoalTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedGoalTemplate) -> [String] {
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

        func requireValid(_ item: BatchedGoalTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedGoalTemplate]) -> [String: [String]] {
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

    static func defaultBatchedGoalTemplateValidator() -> BatchedGoalTemplateValidator {
        return BatchedGoalTemplateValidator(
            rules: [
                BatchedGoalTemplateDosageMgRangeRule(min: 9.4, max: 2130.1),
                BatchedGoalTemplateGraceDaysRangeRule(min: 120, max: 255),
                BatchedGoalTemplateBedLengthRule(maxLength: 86400),
                BatchedGoalTemplateRequiredCodeRule(message: "batched goal template needs a value"),
            ]
        )
    }
}
