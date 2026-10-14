import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched interaction budget must pass. Check returns its problems, or none.
    protocol BatchedInteractionBudgetRule {
        func check(_ item: BatchedInteractionBudget) -> [String]
    }

    final class BatchedInteractionBudgetSourceLengthRule: BatchedInteractionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedInteractionBudget) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedInteractionBudgetArchivedGuardRule: BatchedInteractionBudgetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedInteractionBudget) -> [String] {
            if item.archived && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class BatchedInteractionBudgetCodeLengthRule: BatchedInteractionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedInteractionBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched interaction budget.
    final class BatchedInteractionBudgetValidator {
        var rules: [any BatchedInteractionBudgetRule]

        init(rules: [any BatchedInteractionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedInteractionBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedInteractionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedInteractionBudget]) -> [String: [String]] {
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

    static func defaultBatchedInteractionBudgetValidator() -> BatchedInteractionBudgetValidator {
        return BatchedInteractionBudgetValidator(
            rules: [
                BatchedInteractionBudgetSourceLengthRule(maxLength: 255),
                BatchedInteractionBudgetArchivedGuardRule(limit: 1000),
                BatchedInteractionBudgetCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
