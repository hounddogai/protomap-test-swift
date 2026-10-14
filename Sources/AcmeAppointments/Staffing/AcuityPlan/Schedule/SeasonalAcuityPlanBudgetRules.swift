import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal acuity plan budget must pass. Check returns its problems, or none.
    protocol SeasonalAcuityPlanBudgetRule {
        func check(_ item: SeasonalAcuityPlanBudget) -> [String]
    }

    final class SeasonalAcuityPlanBudgetSpecialtyLengthRule: SeasonalAcuityPlanBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAcuityPlanBudget) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAcuityPlanBudgetRequiredNameRule: SeasonalAcuityPlanBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAcuityPlanBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalAcuityPlanBudgetCodePrefixRule: SeasonalAcuityPlanBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalAcuityPlanBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal acuity plan budget.
    final class SeasonalAcuityPlanBudgetValidator {
        var rules: [any SeasonalAcuityPlanBudgetRule]

        init(rules: [any SeasonalAcuityPlanBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAcuityPlanBudget) -> [String] {
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

        func requireValid(_ item: SeasonalAcuityPlanBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAcuityPlanBudget]) -> [String: [String]] {
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

    static func defaultSeasonalAcuityPlanBudgetValidator() -> SeasonalAcuityPlanBudgetValidator {
        return SeasonalAcuityPlanBudgetValidator(
            rules: [
                SeasonalAcuityPlanBudgetSpecialtyLengthRule(maxLength: 32),
                SeasonalAcuityPlanBudgetRequiredNameRule(message: "seasonal acuity plan budget needs a value"),
                SeasonalAcuityPlanBudgetCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
