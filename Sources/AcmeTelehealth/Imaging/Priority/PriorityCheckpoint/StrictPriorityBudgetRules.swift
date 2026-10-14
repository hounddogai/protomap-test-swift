import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict priority budget must pass. Check returns its problems, or none.
    protocol StrictPriorityBudgetRule {
        func check(_ item: StrictPriorityBudget) -> [String]
    }

    final class StrictPriorityBudgetPatientRefLengthRule: StrictPriorityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictPriorityBudget) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictPriorityBudgetDescriptionLengthRule: StrictPriorityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictPriorityBudget) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictPriorityBudgetRequiredCodeRule: StrictPriorityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictPriorityBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict priority budget.
    final class StrictPriorityBudgetValidator {
        var rules: [any StrictPriorityBudgetRule]

        init(rules: [any StrictPriorityBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictPriorityBudget) -> [String] {
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

        func requireValid(_ item: StrictPriorityBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictPriorityBudget]) -> [String: [String]] {
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

    static func defaultStrictPriorityBudgetValidator() -> StrictPriorityBudgetValidator {
        return StrictPriorityBudgetValidator(
            rules: [
                StrictPriorityBudgetPatientRefLengthRule(maxLength: 80),
                StrictPriorityBudgetDescriptionLengthRule(maxLength: 86400),
                StrictPriorityBudgetRequiredCodeRule(message: "strict priority budget needs an entry"),
            ]
        )
    }
}
