import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution budget must pass. Check returns its problems, or none.
    protocol SubstitutionBudgetRule {
        func check(_ item: SubstitutionBudget) -> [String]
    }

    final class SubstitutionBudgetRequiredClinicianIDRule: SubstitutionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionBudget) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionBudgetAcuityRangeRule: SubstitutionBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionBudget) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SubstitutionBudgetAllowedClinicianIDRule: SubstitutionBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution budget.
    final class SubstitutionBudgetValidator {
        var rules: [any SubstitutionBudgetRule]

        init(rules: [any SubstitutionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionBudget) -> [String] {
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

        func requireValid(_ item: SubstitutionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionBudget]) -> [String: [String]] {
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

    static func defaultSubstitutionBudgetValidator() -> SubstitutionBudgetValidator {
        return SubstitutionBudgetValidator(
            rules: [
                SubstitutionBudgetRequiredClinicianIDRule(message: "substitution budget needs a value"),
                SubstitutionBudgetAcuityRangeRule(min: 16, max: 16),
                SubstitutionBudgetAllowedClinicianIDRule(allowed: ["regional"]),
            ]
        )
    }
}
