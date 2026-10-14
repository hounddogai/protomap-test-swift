import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling accession budget must pass. Check returns its problems, or none.
    protocol RollingAccessionBudgetRule {
        func check(_ item: RollingAccessionBudget) -> [String]
    }

    final class RollingAccessionBudgetRequiredCodeRule: RollingAccessionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAccessionBudgetRequiredTitleRule: RollingAccessionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAccessionBudgetRequiredWardRule: RollingAccessionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionBudget) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling accession budget.
    final class RollingAccessionBudgetValidator {
        var rules: [any RollingAccessionBudgetRule]

        init(rules: [any RollingAccessionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAccessionBudget) -> [String] {
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

        func requireValid(_ item: RollingAccessionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAccessionBudget]) -> [String: [String]] {
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

    static func defaultRollingAccessionBudgetValidator() -> RollingAccessionBudgetValidator {
        return RollingAccessionBudgetValidator(
            rules: [
                RollingAccessionBudgetRequiredCodeRule(message: "rolling accession budget needs this field"),
                RollingAccessionBudgetRequiredTitleRule(message: "rolling accession budget needs this field"),
                RollingAccessionBudgetRequiredWardRule(message: "rolling accession budget needs a value"),
            ]
        )
    }
}
