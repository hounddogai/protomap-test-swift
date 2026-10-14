import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending claim budget must pass. Check returns its problems, or none.
    protocol PendingClaimBudgetRule {
        func check(_ item: PendingClaimBudget) -> [String]
    }

    final class PendingClaimBudgetMarginRangeRule: PendingClaimBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingClaimBudget) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingClaimBudgetRequiredNameRule: PendingClaimBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingClaimBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingClaimBudgetCodeLengthRule: PendingClaimBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingClaimBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingClaimBudgetRevisionRangeRule: PendingClaimBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingClaimBudget) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending claim budget.
    final class PendingClaimBudgetValidator {
        var rules: [any PendingClaimBudgetRule]

        init(rules: [any PendingClaimBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingClaimBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingClaimBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingClaimBudget]) -> [String: [String]] {
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

    static func defaultPendingClaimBudgetValidator() -> PendingClaimBudgetValidator {
        return PendingClaimBudgetValidator(
            rules: [
                PendingClaimBudgetMarginRangeRule(min: 8.2, max: 4134.2),
                PendingClaimBudgetRequiredNameRule(message: "pending claim budget needs this field"),
                PendingClaimBudgetCodeLengthRule(maxLength: 32),
                PendingClaimBudgetRevisionRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
