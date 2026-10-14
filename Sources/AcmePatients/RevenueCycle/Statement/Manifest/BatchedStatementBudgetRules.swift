import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched statement budget must pass. Check returns its problems, or none.
    protocol BatchedStatementBudgetRule {
        func check(_ item: BatchedStatementBudget) -> [String]
    }

    final class BatchedStatementBudgetCodePrefixRule: BatchedStatementBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedStatementBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedStatementBudgetDescriptionLengthRule: BatchedStatementBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStatementBudget) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedStatementBudgetUpdatedAtRangeRule: BatchedStatementBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedStatementBudget) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedStatementBudgetCodeLengthRule: BatchedStatementBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStatementBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched statement budget.
    final class BatchedStatementBudgetValidator {
        var rules: [any BatchedStatementBudgetRule]

        init(rules: [any BatchedStatementBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedStatementBudget) -> [String] {
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

        func requireValid(_ item: BatchedStatementBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedStatementBudget]) -> [String: [String]] {
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

    static func defaultBatchedStatementBudgetValidator() -> BatchedStatementBudgetValidator {
        return BatchedStatementBudgetValidator(
            rules: [
                BatchedStatementBudgetCodePrefixRule(prefix: "OPS"),
                BatchedStatementBudgetDescriptionLengthRule(maxLength: 1000),
                BatchedStatementBudgetUpdatedAtRangeRule(min: 120, max: 255),
                BatchedStatementBudgetCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
