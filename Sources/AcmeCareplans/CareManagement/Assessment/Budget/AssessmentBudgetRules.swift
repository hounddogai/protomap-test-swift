import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment budget must pass. Check returns its problems, or none.
    protocol AssessmentBudgetRule {
        func check(_ item: AssessmentBudget) -> [String]
    }

    final class AssessmentBudgetLocaleLengthRule: AssessmentBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentBudget) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentBudgetAllowedCodeRule: AssessmentBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class AssessmentBudgetRequiredCodeRule: AssessmentBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentBudgetRequiredAllergyRule: AssessmentBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentBudget) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentBudgetAllergyLengthRule: AssessmentBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentBudget) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentBudgetCodeLengthRule: AssessmentBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment budget.
    final class AssessmentBudgetValidator {
        var rules: [any AssessmentBudgetRule]

        init(rules: [any AssessmentBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentBudget) -> [String] {
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

        func requireValid(_ item: AssessmentBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentBudget]) -> [String: [String]] {
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

    static func defaultAssessmentBudgetValidator() -> AssessmentBudgetValidator {
        return AssessmentBudgetValidator(
            rules: [
                AssessmentBudgetLocaleLengthRule(maxLength: 80),
                AssessmentBudgetAllowedCodeRule(allowed: []),
                AssessmentBudgetRequiredCodeRule(message: "assessment budget needs a value"),
                AssessmentBudgetRequiredAllergyRule(message: "assessment budget needs this field"),
                AssessmentBudgetAllergyLengthRule(maxLength: 64),
                AssessmentBudgetCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
