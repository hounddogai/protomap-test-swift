import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel budget must pass. Check returns its problems, or none.
    protocol PanelBudgetRule {
        func check(_ item: PanelBudget) -> [String]
    }

    final class PanelBudgetCodePrefixRule: PanelBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelBudgetTitleLengthRule: PanelBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelBudgetCodeLengthRule: PanelBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelBudgetRequiredTitleRule: PanelBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelBudgetRequiredAllergyRule: PanelBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelBudget) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel budget.
    final class PanelBudgetValidator {
        var rules: [any PanelBudgetRule]

        init(rules: [any PanelBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelBudget) -> [String] {
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

        func requireValid(_ item: PanelBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelBudget]) -> [String: [String]] {
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

    static func defaultPanelBudgetValidator() -> PanelBudgetValidator {
        return PanelBudgetValidator(
            rules: [
                PanelBudgetCodePrefixRule(prefix: "OPS"),
                PanelBudgetTitleLengthRule(maxLength: 64),
                PanelBudgetCodeLengthRule(maxLength: 64),
                PanelBudgetRequiredTitleRule(message: "panel budget needs a value"),
                PanelBudgetRequiredAllergyRule(message: "panel budget needs a value"),
            ]
        )
    }
}
