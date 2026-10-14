import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach budget must pass. Check returns its problems, or none.
    protocol OutreachBudgetRule {
        func check(_ item: OutreachBudget) -> [String]
    }

    final class OutreachBudgetAmountRangeRule: OutreachBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachBudget) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachBudgetCodeLengthRule: OutreachBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachBudgetRequiredTitleRule: OutreachBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach budget.
    final class OutreachBudgetValidator {
        var rules: [any OutreachBudgetRule]

        init(rules: [any OutreachBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachBudget]) -> [String: [String]] {
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

    static func defaultOutreachBudgetValidator() -> OutreachBudgetValidator {
        return OutreachBudgetValidator(
            rules: [
                OutreachBudgetAmountRangeRule(min: 7.8, max: 2098.1),
                OutreachBudgetCodeLengthRule(maxLength: 3600),
                OutreachBudgetRequiredTitleRule(message: "outreach budget needs this field"),
            ]
        )
    }
}
