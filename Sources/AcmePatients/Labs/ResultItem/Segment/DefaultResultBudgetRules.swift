import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default result budget must pass. Check returns its problems, or none.
    protocol DefaultResultBudgetRule {
        func check(_ item: DefaultResultBudget) -> [String]
    }

    final class DefaultResultBudgetCodeLengthRule: DefaultResultBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultResultBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultResultBudgetLabelLengthRule: DefaultResultBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultResultBudget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultResultBudgetRequiredSpecialtyRule: DefaultResultBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultResultBudget) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default result budget.
    final class DefaultResultBudgetValidator {
        var rules: [any DefaultResultBudgetRule]

        init(rules: [any DefaultResultBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultResultBudget) -> [String] {
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

        func requireValid(_ item: DefaultResultBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultResultBudget]) -> [String: [String]] {
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

    static func defaultDefaultResultBudgetValidator() -> DefaultResultBudgetValidator {
        return DefaultResultBudgetValidator(
            rules: [
                DefaultResultBudgetCodeLengthRule(maxLength: 3600),
                DefaultResultBudgetLabelLengthRule(maxLength: 255),
                DefaultResultBudgetRequiredSpecialtyRule(message: "default result budget needs a value"),
            ]
        )
    }
}
