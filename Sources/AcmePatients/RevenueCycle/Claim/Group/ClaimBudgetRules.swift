import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim budget must pass. Check returns its problems, or none.
    protocol ClaimBudgetRule {
        func check(_ item: ClaimBudget) -> [String]
    }

    final class ClaimBudgetRequiredEncounterIDRule: ClaimBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimBudget) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimBudgetRequiredCodeRule: ClaimBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimBudgetNotesLengthRule: ClaimBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimBudget) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimBudgetUpdatedAtRangeRule: ClaimBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimBudget) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim budget.
    final class ClaimBudgetValidator {
        var rules: [any ClaimBudgetRule]

        init(rules: [any ClaimBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimBudget) -> [String] {
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

        func requireValid(_ item: ClaimBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimBudget]) -> [String: [String]] {
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

    static func defaultClaimBudgetValidator() -> ClaimBudgetValidator {
        return ClaimBudgetValidator(
            rules: [
                ClaimBudgetRequiredEncounterIDRule(message: "claim budget needs a value"),
                ClaimBudgetRequiredCodeRule(message: "claim budget needs this field"),
                ClaimBudgetNotesLengthRule(maxLength: 86400),
                ClaimBudgetUpdatedAtRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
