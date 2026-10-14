import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board budget must pass. Check returns its problems, or none.
    protocol BedBoardBudgetRule {
        func check(_ item: BedBoardBudget) -> [String]
    }

    final class BedBoardBudgetAllowedCodeRule: BedBoardBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class BedBoardBudgetRequiredCodeRule: BedBoardBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardBudgetMaximumRangeRule: BedBoardBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardBudget) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardBudgetAttemptsRangeRule: BedBoardBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardBudget) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a bed board budget.
    final class BedBoardBudgetValidator {
        var rules: [any BedBoardBudgetRule]

        init(rules: [any BedBoardBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardBudget]) -> [String: [String]] {
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

    static func defaultBedBoardBudgetValidator() -> BedBoardBudgetValidator {
        return BedBoardBudgetValidator(
            rules: [
                BedBoardBudgetAllowedCodeRule(allowed: ["default", "seasonal", "global"]),
                BedBoardBudgetRequiredCodeRule(message: "bed board budget needs a value"),
                BedBoardBudgetMaximumRangeRule(min: 4.3, max: 993.9),
                BedBoardBudgetAttemptsRangeRule(min: 80, max: 120),
            ]
        )
    }
}
