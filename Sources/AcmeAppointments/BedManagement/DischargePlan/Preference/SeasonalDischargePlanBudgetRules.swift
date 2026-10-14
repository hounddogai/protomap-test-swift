import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal discharge plan budget must pass. Check returns its problems, or none.
    protocol SeasonalDischargePlanBudgetRule {
        func check(_ item: SeasonalDischargePlanBudget) -> [String]
    }

    final class SeasonalDischargePlanBudgetStartsAtRangeRule: SeasonalDischargePlanBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDischargePlanBudget) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalDischargePlanBudgetRevisionRangeRule: SeasonalDischargePlanBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDischargePlanBudget) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalDischargePlanBudgetRequiredCodeRule: SeasonalDischargePlanBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalDischargePlanBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalDischargePlanBudgetCodeLengthRule: SeasonalDischargePlanBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalDischargePlanBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal discharge plan budget.
    final class SeasonalDischargePlanBudgetValidator {
        var rules: [any SeasonalDischargePlanBudgetRule]

        init(rules: [any SeasonalDischargePlanBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalDischargePlanBudget) -> [String] {
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

        func requireValid(_ item: SeasonalDischargePlanBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalDischargePlanBudget]) -> [String: [String]] {
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

    static func defaultSeasonalDischargePlanBudgetValidator() -> SeasonalDischargePlanBudgetValidator {
        return SeasonalDischargePlanBudgetValidator(
            rules: [
                SeasonalDischargePlanBudgetStartsAtRangeRule(min: 64, max: 120),
                SeasonalDischargePlanBudgetRevisionRangeRule(min: 32, max: 86400),
                SeasonalDischargePlanBudgetRequiredCodeRule(message: "seasonal discharge plan budget needs a value"),
                SeasonalDischargePlanBudgetCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
