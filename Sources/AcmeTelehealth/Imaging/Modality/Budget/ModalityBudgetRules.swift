import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality budget must pass. Check returns its problems, or none.
    protocol ModalityBudgetRule {
        func check(_ item: ModalityBudget) -> [String]
    }

    final class ModalityBudgetCodePrefixRule: ModalityBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalityBudgetAllowedUnitRule: ModalityBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is below minimum"]
            }
            return []
        }
    }

    final class ModalityBudgetRequiredLabelRule: ModalityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityBudget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityBudgetRequiredCodeRule: ModalityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality budget.
    final class ModalityBudgetValidator {
        var rules: [any ModalityBudgetRule]

        init(rules: [any ModalityBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityBudget) -> [String] {
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

        func requireValid(_ item: ModalityBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityBudget]) -> [String: [String]] {
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

    static func defaultModalityBudgetValidator() -> ModalityBudgetValidator {
        return ModalityBudgetValidator(
            rules: [
                ModalityBudgetCodePrefixRule(prefix: "Q"),
                ModalityBudgetAllowedUnitRule(allowed: []),
                ModalityBudgetRequiredLabelRule(message: "modality budget needs a value"),
                ModalityBudgetRequiredCodeRule(message: "modality budget needs an entry"),
            ]
        )
    }
}
