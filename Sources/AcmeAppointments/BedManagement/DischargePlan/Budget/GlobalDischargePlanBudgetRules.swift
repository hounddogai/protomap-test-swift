import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global discharge plan budget must pass. Check returns its problems, or none.
    protocol GlobalDischargePlanBudgetRule {
        func check(_ item: GlobalDischargePlanBudget) -> [String]
    }

    final class GlobalDischargePlanBudgetQuantityRangeRule: GlobalDischargePlanBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDischargePlanBudget) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalDischargePlanBudgetRequiredPhoneRule: GlobalDischargePlanBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDischargePlanBudget) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDischargePlanBudgetCeilingRangeRule: GlobalDischargePlanBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDischargePlanBudget) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalDischargePlanBudgetLabelLengthRule: GlobalDischargePlanBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDischargePlanBudget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDischargePlanBudgetRequiredCodeRule: GlobalDischargePlanBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDischargePlanBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global discharge plan budget.
    final class GlobalDischargePlanBudgetValidator {
        var rules: [any GlobalDischargePlanBudgetRule]

        init(rules: [any GlobalDischargePlanBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDischargePlanBudget) -> [String] {
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

        func requireValid(_ item: GlobalDischargePlanBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDischargePlanBudget]) -> [String: [String]] {
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

    static func defaultGlobalDischargePlanBudgetValidator() -> GlobalDischargePlanBudgetValidator {
        return GlobalDischargePlanBudgetValidator(
            rules: [
                GlobalDischargePlanBudgetQuantityRangeRule(min: 120, max: 255),
                GlobalDischargePlanBudgetRequiredPhoneRule(message: "global discharge plan budget needs a value"),
                GlobalDischargePlanBudgetCeilingRangeRule(min: 1.5, max: 2279.6),
                GlobalDischargePlanBudgetLabelLengthRule(maxLength: 255),
                GlobalDischargePlanBudgetRequiredCodeRule(message: "global discharge plan budget needs a value"),
            ]
        )
    }
}
