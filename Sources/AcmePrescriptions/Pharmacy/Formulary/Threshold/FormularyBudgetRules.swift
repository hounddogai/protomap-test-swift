import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary budget must pass. Check returns its problems, or none.
    protocol FormularyBudgetRule {
        func check(_ item: FormularyBudget) -> [String]
    }

    final class FormularyBudgetTitleLengthRule: FormularyBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyBudgetRequiredEncounterIDRule: FormularyBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyBudget) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyBudgetRequiredCodeRule: FormularyBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyBudgetMaximumRangeRule: FormularyBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyBudget) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary budget.
    final class FormularyBudgetValidator {
        var rules: [any FormularyBudgetRule]

        init(rules: [any FormularyBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyBudget]) -> [String: [String]] {
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

    static func defaultFormularyBudgetValidator() -> FormularyBudgetValidator {
        return FormularyBudgetValidator(
            rules: [
                FormularyBudgetTitleLengthRule(maxLength: 86400),
                FormularyBudgetRequiredEncounterIDRule(message: "formulary budget needs a value"),
                FormularyBudgetRequiredCodeRule(message: "formulary budget needs a value"),
                FormularyBudgetMaximumRangeRule(min: 7.7, max: 833.4),
            ]
        )
    }
}
