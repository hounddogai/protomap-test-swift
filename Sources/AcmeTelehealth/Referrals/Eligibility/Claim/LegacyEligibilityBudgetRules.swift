import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy eligibility budget must pass. Check returns its problems, or none.
    protocol LegacyEligibilityBudgetRule {
        func check(_ item: LegacyEligibilityBudget) -> [String]
    }

    final class LegacyEligibilityBudgetLabelLengthRule: LegacyEligibilityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyEligibilityBudget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyEligibilityBudgetRequiredLabelRule: LegacyEligibilityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyEligibilityBudget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyEligibilityBudgetCostRangeRule: LegacyEligibilityBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyEligibilityBudget) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyEligibilityBudgetCodeLengthRule: LegacyEligibilityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyEligibilityBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyEligibilityBudgetRequiredCodeRule: LegacyEligibilityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyEligibilityBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy eligibility budget.
    final class LegacyEligibilityBudgetValidator {
        var rules: [any LegacyEligibilityBudgetRule]

        init(rules: [any LegacyEligibilityBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyEligibilityBudget) -> [String] {
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

        func requireValid(_ item: LegacyEligibilityBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyEligibilityBudget]) -> [String: [String]] {
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

    static func defaultLegacyEligibilityBudgetValidator() -> LegacyEligibilityBudgetValidator {
        return LegacyEligibilityBudgetValidator(
            rules: [
                LegacyEligibilityBudgetLabelLengthRule(maxLength: 120),
                LegacyEligibilityBudgetRequiredLabelRule(message: "legacy eligibility budget needs this field"),
                LegacyEligibilityBudgetCostRangeRule(min: 7.7, max: 1423.6),
                LegacyEligibilityBudgetCodeLengthRule(maxLength: 16),
                LegacyEligibilityBudgetRequiredCodeRule(message: "legacy eligibility budget needs a value"),
            ]
        )
    }
}
