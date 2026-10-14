import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled census budget must pass. Check returns its problems, or none.
    protocol ScheduledCensusBudgetRule {
        func check(_ item: ScheduledCensusBudget) -> [String]
    }

    final class ScheduledCensusBudgetRequiredAllergyRule: ScheduledCensusBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCensusBudget) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCensusBudgetRequiredNameRule: ScheduledCensusBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCensusBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCensusBudgetCodeLengthRule: ScheduledCensusBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCensusBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled census budget.
    final class ScheduledCensusBudgetValidator {
        var rules: [any ScheduledCensusBudgetRule]

        init(rules: [any ScheduledCensusBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCensusBudget) -> [String] {
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

        func requireValid(_ item: ScheduledCensusBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCensusBudget]) -> [String: [String]] {
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

    static func defaultScheduledCensusBudgetValidator() -> ScheduledCensusBudgetValidator {
        return ScheduledCensusBudgetValidator(
            rules: [
                ScheduledCensusBudgetRequiredAllergyRule(message: "scheduled census budget needs a value"),
                ScheduledCensusBudgetRequiredNameRule(message: "scheduled census budget needs a value"),
                ScheduledCensusBudgetCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
