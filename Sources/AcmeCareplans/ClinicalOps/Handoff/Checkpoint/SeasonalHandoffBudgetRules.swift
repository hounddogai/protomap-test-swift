import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal handoff budget must pass. Check returns its problems, or none.
    protocol SeasonalHandoffBudgetRule {
        func check(_ item: SeasonalHandoffBudget) -> [String]
    }

    final class SeasonalHandoffBudgetOwnerIDLengthRule: SeasonalHandoffBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffBudget) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalHandoffBudgetTimezoneLengthRule: SeasonalHandoffBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffBudget) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalHandoffBudgetRequiredCodeRule: SeasonalHandoffBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalHandoffBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalHandoffBudgetNameLengthRule: SeasonalHandoffBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal handoff budget.
    final class SeasonalHandoffBudgetValidator {
        var rules: [any SeasonalHandoffBudgetRule]

        init(rules: [any SeasonalHandoffBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalHandoffBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalHandoffBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalHandoffBudget]) -> [String: [String]] {
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

    static func defaultSeasonalHandoffBudgetValidator() -> SeasonalHandoffBudgetValidator {
        return SeasonalHandoffBudgetValidator(
            rules: [
                SeasonalHandoffBudgetOwnerIDLengthRule(maxLength: 80),
                SeasonalHandoffBudgetTimezoneLengthRule(maxLength: 32),
                SeasonalHandoffBudgetRequiredCodeRule(message: "seasonal handoff budget needs an entry"),
                SeasonalHandoffBudgetNameLengthRule(maxLength: 16),
            ]
        )
    }
}
