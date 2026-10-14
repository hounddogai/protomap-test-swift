import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive accession budget must pass. Check returns its problems, or none.
    protocol AdaptiveAccessionBudgetRule {
        func check(_ item: AdaptiveAccessionBudget) -> [String]
    }

    final class AdaptiveAccessionBudgetRequiredSpecialtyRule: AdaptiveAccessionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAccessionBudget) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveAccessionBudgetRetriesRangeRule: AdaptiveAccessionBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAccessionBudget) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveAccessionBudgetCodeLengthRule: AdaptiveAccessionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAccessionBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveAccessionBudgetProcedureCodeLengthRule: AdaptiveAccessionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveAccessionBudget) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive accession budget.
    final class AdaptiveAccessionBudgetValidator {
        var rules: [any AdaptiveAccessionBudgetRule]

        init(rules: [any AdaptiveAccessionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAccessionBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveAccessionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAccessionBudget]) -> [String: [String]] {
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

    static func defaultAdaptiveAccessionBudgetValidator() -> AdaptiveAccessionBudgetValidator {
        return AdaptiveAccessionBudgetValidator(
            rules: [
                AdaptiveAccessionBudgetRequiredSpecialtyRule(message: "adaptive accession budget needs a value"),
                AdaptiveAccessionBudgetRetriesRangeRule(min: 16, max: 255),
                AdaptiveAccessionBudgetCodeLengthRule(maxLength: 16),
                AdaptiveAccessionBudgetProcedureCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
