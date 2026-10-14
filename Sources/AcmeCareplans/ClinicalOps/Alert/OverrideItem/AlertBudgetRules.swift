import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert budget must pass. Check returns its problems, or none.
    protocol AlertBudgetRule {
        func check(_ item: AlertBudget) -> [String]
    }

    final class AlertBudgetDiscountRangeRule: AlertBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertBudget) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertBudgetTitleLengthRule: AlertBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertBudgetRequiredSegmentRule: AlertBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertBudget) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert budget.
    final class AlertBudgetValidator {
        var rules: [any AlertBudgetRule]

        init(rules: [any AlertBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertBudget) -> [String] {
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

        func requireValid(_ item: AlertBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertBudget]) -> [String: [String]] {
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

    static func defaultAlertBudgetValidator() -> AlertBudgetValidator {
        return AlertBudgetValidator(
            rules: [
                AlertBudgetDiscountRangeRule(min: 9.7, max: 1918.9),
                AlertBudgetTitleLengthRule(maxLength: 3600),
                AlertBudgetRequiredSegmentRule(message: "alert budget needs this field"),
            ]
        )
    }
}
