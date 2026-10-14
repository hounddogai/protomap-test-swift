import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual formulary budget must pass. Check returns its problems, or none.
    protocol ManualFormularyBudgetRule {
        func check(_ item: ManualFormularyBudget) -> [String]
    }

    final class ManualFormularyBudgetCategoryLengthRule: ManualFormularyBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFormularyBudget) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFormularyBudgetLimitRangeRule: ManualFormularyBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualFormularyBudget) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualFormularyBudgetRequiredDescriptionRule: ManualFormularyBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFormularyBudget) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualFormularyBudgetAllowedDescriptionRule: ManualFormularyBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualFormularyBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is inconsistent"]
            }
            return []
        }
    }

    final class ManualFormularyBudgetCodeLengthRule: ManualFormularyBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFormularyBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual formulary budget.
    final class ManualFormularyBudgetValidator {
        var rules: [any ManualFormularyBudgetRule]

        init(rules: [any ManualFormularyBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualFormularyBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualFormularyBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualFormularyBudget]) -> [String: [String]] {
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

    static func defaultManualFormularyBudgetValidator() -> ManualFormularyBudgetValidator {
        return ManualFormularyBudgetValidator(
            rules: [
                ManualFormularyBudgetCategoryLengthRule(maxLength: 255),
                ManualFormularyBudgetLimitRangeRule(min: 32, max: 120),
                ManualFormularyBudgetRequiredDescriptionRule(message: "manual formulary budget needs an entry"),
                ManualFormularyBudgetAllowedDescriptionRule(allowed: []),
                ManualFormularyBudgetCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
