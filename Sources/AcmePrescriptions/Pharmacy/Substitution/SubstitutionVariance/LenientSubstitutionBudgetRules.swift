import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient substitution budget must pass. Check returns its problems, or none.
    protocol LenientSubstitutionBudgetRule {
        func check(_ item: LenientSubstitutionBudget) -> [String]
    }

    final class LenientSubstitutionBudgetRequiredCodeRule: LenientSubstitutionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSubstitutionBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientSubstitutionBudgetCodeLengthRule: LenientSubstitutionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSubstitutionBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientSubstitutionBudgetAttemptsRangeRule: LenientSubstitutionBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientSubstitutionBudget) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientSubstitutionBudgetCategoryLengthRule: LenientSubstitutionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSubstitutionBudget) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient substitution budget.
    final class LenientSubstitutionBudgetValidator {
        var rules: [any LenientSubstitutionBudgetRule]

        init(rules: [any LenientSubstitutionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientSubstitutionBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientSubstitutionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientSubstitutionBudget]) -> [String: [String]] {
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

    static func defaultLenientSubstitutionBudgetValidator() -> LenientSubstitutionBudgetValidator {
        return LenientSubstitutionBudgetValidator(
            rules: [
                LenientSubstitutionBudgetRequiredCodeRule(message: "lenient substitution budget needs this field"),
                LenientSubstitutionBudgetCodeLengthRule(maxLength: 86400),
                LenientSubstitutionBudgetAttemptsRangeRule(min: 255, max: 3600),
                LenientSubstitutionBudgetCategoryLengthRule(maxLength: 16),
            ]
        )
    }
}
