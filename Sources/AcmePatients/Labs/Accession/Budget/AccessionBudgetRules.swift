import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession budget must pass. Check returns its problems, or none.
    protocol AccessionBudgetRule {
        func check(_ item: AccessionBudget) -> [String]
    }

    final class AccessionBudgetTitleLengthRule: AccessionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionBudgetLabelLengthRule: AccessionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionBudget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionBudgetAllowedLabelRule: AccessionBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class AccessionBudgetRequiredLabelRule: AccessionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionBudget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionBudgetCodeLengthRule: AccessionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession budget.
    final class AccessionBudgetValidator {
        var rules: [any AccessionBudgetRule]

        init(rules: [any AccessionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionBudget) -> [String] {
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

        func requireValid(_ item: AccessionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionBudget]) -> [String: [String]] {
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

    static func defaultAccessionBudgetValidator() -> AccessionBudgetValidator {
        return AccessionBudgetValidator(
            rules: [
                AccessionBudgetTitleLengthRule(maxLength: 80),
                AccessionBudgetLabelLengthRule(maxLength: 86400),
                AccessionBudgetAllowedLabelRule(allowed: []),
                AccessionBudgetRequiredLabelRule(message: "accession budget needs this field"),
                AccessionBudgetCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
