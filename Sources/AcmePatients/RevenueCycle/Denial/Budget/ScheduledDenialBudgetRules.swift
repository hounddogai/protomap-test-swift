import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled denial budget must pass. Check returns its problems, or none.
    protocol ScheduledDenialBudgetRule {
        func check(_ item: ScheduledDenialBudget) -> [String]
    }

    final class ScheduledDenialBudgetRequiredDiagnosisCodeRule: ScheduledDenialBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDenialBudget) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledDenialBudgetRequiredTitleRule: ScheduledDenialBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDenialBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledDenialBudgetDiagnosisCodeLengthRule: ScheduledDenialBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledDenialBudget) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledDenialBudgetRequiredCodeRule: ScheduledDenialBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDenialBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled denial budget.
    final class ScheduledDenialBudgetValidator {
        var rules: [any ScheduledDenialBudgetRule]

        init(rules: [any ScheduledDenialBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledDenialBudget) -> [String] {
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

        func requireValid(_ item: ScheduledDenialBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledDenialBudget]) -> [String: [String]] {
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

    static func defaultScheduledDenialBudgetValidator() -> ScheduledDenialBudgetValidator {
        return ScheduledDenialBudgetValidator(
            rules: [
                ScheduledDenialBudgetRequiredDiagnosisCodeRule(message: "scheduled denial budget needs this field"),
                ScheduledDenialBudgetRequiredTitleRule(message: "scheduled denial budget needs a value"),
                ScheduledDenialBudgetDiagnosisCodeLengthRule(maxLength: 1000),
                ScheduledDenialBudgetRequiredCodeRule(message: "scheduled denial budget needs an entry"),
            ]
        )
    }
}
