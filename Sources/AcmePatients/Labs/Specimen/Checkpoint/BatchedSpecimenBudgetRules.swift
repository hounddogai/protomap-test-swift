import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched specimen budget must pass. Check returns its problems, or none.
    protocol BatchedSpecimenBudgetRule {
        func check(_ item: BatchedSpecimenBudget) -> [String]
    }

    final class BatchedSpecimenBudgetRequiredCodeRule: BatchedSpecimenBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSpecimenBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSpecimenBudgetRequiredSummaryRule: BatchedSpecimenBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSpecimenBudget) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSpecimenBudgetCodePrefixRule: BatchedSpecimenBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedSpecimenBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedSpecimenBudgetEncounterIDLengthRule: BatchedSpecimenBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSpecimenBudget) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched specimen budget.
    final class BatchedSpecimenBudgetValidator {
        var rules: [any BatchedSpecimenBudgetRule]

        init(rules: [any BatchedSpecimenBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSpecimenBudget) -> [String] {
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

        func requireValid(_ item: BatchedSpecimenBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSpecimenBudget]) -> [String: [String]] {
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

    static func defaultBatchedSpecimenBudgetValidator() -> BatchedSpecimenBudgetValidator {
        return BatchedSpecimenBudgetValidator(
            rules: [
                BatchedSpecimenBudgetRequiredCodeRule(message: "batched specimen budget needs a value"),
                BatchedSpecimenBudgetRequiredSummaryRule(message: "batched specimen budget needs a value"),
                BatchedSpecimenBudgetCodePrefixRule(prefix: "OPS"),
                BatchedSpecimenBudgetEncounterIDLengthRule(maxLength: 86400),
            ]
        )
    }
}
