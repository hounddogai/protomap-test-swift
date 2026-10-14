import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual rounding budget must pass. Check returns its problems, or none.
    protocol ManualRoundingBudgetRule {
        func check(_ item: ManualRoundingBudget) -> [String]
    }

    final class ManualRoundingBudgetFloorValueRangeRule: ManualRoundingBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRoundingBudget) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualRoundingBudgetTitleLengthRule: ManualRoundingBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRoundingBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRoundingBudgetRequiredTitleRule: ManualRoundingBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRoundingBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRoundingBudgetVisitMinutesRangeRule: ManualRoundingBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRoundingBudget) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRoundingBudgetRequiredCodeRule: ManualRoundingBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRoundingBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRoundingBudgetCodeLengthRule: ManualRoundingBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRoundingBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual rounding budget.
    final class ManualRoundingBudgetValidator {
        var rules: [any ManualRoundingBudgetRule]

        init(rules: [any ManualRoundingBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRoundingBudget) -> [String] {
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

        func requireValid(_ item: ManualRoundingBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRoundingBudget]) -> [String: [String]] {
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

    static func defaultManualRoundingBudgetValidator() -> ManualRoundingBudgetValidator {
        return ManualRoundingBudgetValidator(
            rules: [
                ManualRoundingBudgetFloorValueRangeRule(min: 6.1, max: 89.9),
                ManualRoundingBudgetTitleLengthRule(maxLength: 3600),
                ManualRoundingBudgetRequiredTitleRule(message: "manual rounding budget needs a value"),
                ManualRoundingBudgetVisitMinutesRangeRule(min: 16, max: 120),
                ManualRoundingBudgetRequiredCodeRule(message: "manual rounding budget needs a value"),
                ManualRoundingBudgetCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
