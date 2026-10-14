import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority budget must pass. Check returns its problems, or none.
    protocol PriorityBudgetRule {
        func check(_ item: PriorityBudget) -> [String]
    }

    final class PriorityBudgetRequiredNameRule: PriorityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityBudgetRequiredBedRule: PriorityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityBudget) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityBudgetAllergyLengthRule: PriorityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityBudget) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityBudgetRequiredAllergyRule: PriorityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityBudget) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityBudgetBedLengthRule: PriorityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityBudget) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityBudgetDosageMgRangeRule: PriorityBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityBudget) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority budget.
    final class PriorityBudgetValidator {
        var rules: [any PriorityBudgetRule]

        init(rules: [any PriorityBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityBudget) -> [String] {
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

        func requireValid(_ item: PriorityBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityBudget]) -> [String: [String]] {
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

    static func defaultPriorityBudgetValidator() -> PriorityBudgetValidator {
        return PriorityBudgetValidator(
            rules: [
                PriorityBudgetRequiredNameRule(message: "priority budget needs a value"),
                PriorityBudgetRequiredBedRule(message: "priority budget needs this field"),
                PriorityBudgetAllergyLengthRule(maxLength: 32),
                PriorityBudgetRequiredAllergyRule(message: "priority budget needs a value"),
                PriorityBudgetBedLengthRule(maxLength: 1000),
                PriorityBudgetDosageMgRangeRule(min: 7.8, max: 3759.3),
            ]
        )
    }
}
