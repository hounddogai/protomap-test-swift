import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot budget must pass. Check returns its problems, or none.
    protocol SlotBudgetRule {
        func check(_ item: SlotBudget) -> [String]
    }

    final class SlotBudgetDurationMinutesRangeRule: SlotBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotBudget) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotBudgetCurrencyLengthRule: SlotBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotBudget) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotBudgetPriorityRangeRule: SlotBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotBudget) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a slot budget.
    final class SlotBudgetValidator {
        var rules: [any SlotBudgetRule]

        init(rules: [any SlotBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotBudget]) -> [String: [String]] {
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

    static func defaultSlotBudgetValidator() -> SlotBudgetValidator {
        return SlotBudgetValidator(
            rules: [
                SlotBudgetDurationMinutesRangeRule(min: 255, max: 86400),
                SlotBudgetCurrencyLengthRule(maxLength: 16),
                SlotBudgetPriorityRangeRule(min: 16, max: 120),
            ]
        )
    }
}
