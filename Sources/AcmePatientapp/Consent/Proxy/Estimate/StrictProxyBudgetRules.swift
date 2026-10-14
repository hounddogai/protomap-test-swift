import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict proxy budget must pass. Check returns its problems, or none.
    protocol StrictProxyBudgetRule {
        func check(_ item: StrictProxyBudget) -> [String]
    }

    final class StrictProxyBudgetBudgetRangeRule: StrictProxyBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProxyBudget) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictProxyBudgetCapacityRangeRule: StrictProxyBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProxyBudget) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictProxyBudgetRequiredTitleRule: StrictProxyBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictProxyBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict proxy budget.
    final class StrictProxyBudgetValidator {
        var rules: [any StrictProxyBudgetRule]

        init(rules: [any StrictProxyBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictProxyBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictProxyBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictProxyBudget]) -> [String: [String]] {
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

    static func defaultStrictProxyBudgetValidator() -> StrictProxyBudgetValidator {
        return StrictProxyBudgetValidator(
            rules: [
                StrictProxyBudgetBudgetRangeRule(min: 1.8, max: 84.2),
                StrictProxyBudgetCapacityRangeRule(min: 80, max: 1000),
                StrictProxyBudgetRequiredTitleRule(message: "strict proxy budget needs a value"),
            ]
        )
    }
}
