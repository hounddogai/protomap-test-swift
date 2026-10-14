import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal batch must pass. Check returns its problems, or none.
    protocol GoalBatchRule {
        func check(_ item: GoalBatch) -> [String]
    }

    final class GoalBatchCodePrefixRule: GoalBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalBatchSummaryLengthRule: GoalBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalBatch) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalBatchRequiredSummaryRule: GoalBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalBatch) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal batch.
    final class GoalBatchValidator {
        var rules: [any GoalBatchRule]

        init(rules: [any GoalBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalBatch) -> [String] {
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

        func requireValid(_ item: GoalBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalBatch]) -> [String: [String]] {
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

    static func defaultGoalBatchValidator() -> GoalBatchValidator {
        return GoalBatchValidator(
            rules: [
                GoalBatchCodePrefixRule(prefix: "OPS"),
                GoalBatchSummaryLengthRule(maxLength: 64),
                GoalBatchRequiredSummaryRule(message: "goal batch needs a value"),
            ]
        )
    }
}
