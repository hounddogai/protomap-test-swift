import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global interaction budget must pass. Check returns its problems, or none.
    protocol GlobalInteractionBudgetRule {
        func check(_ item: GlobalInteractionBudget) -> [String]
    }

    final class GlobalInteractionBudgetCodeLengthRule: GlobalInteractionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInteractionBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInteractionBudgetRequiredProcedureCodeRule: GlobalInteractionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalInteractionBudget) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalInteractionBudgetNameLengthRule: GlobalInteractionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInteractionBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInteractionBudgetProcedureCodeLengthRule: GlobalInteractionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInteractionBudget) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global interaction budget.
    final class GlobalInteractionBudgetValidator {
        var rules: [any GlobalInteractionBudgetRule]

        init(rules: [any GlobalInteractionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalInteractionBudget) -> [String] {
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

        func requireValid(_ item: GlobalInteractionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalInteractionBudget]) -> [String: [String]] {
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

    static func defaultGlobalInteractionBudgetValidator() -> GlobalInteractionBudgetValidator {
        return GlobalInteractionBudgetValidator(
            rules: [
                GlobalInteractionBudgetCodeLengthRule(maxLength: 32),
                GlobalInteractionBudgetRequiredProcedureCodeRule(message: "global interaction budget needs a value"),
                GlobalInteractionBudgetNameLengthRule(maxLength: 16),
                GlobalInteractionBudgetProcedureCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
