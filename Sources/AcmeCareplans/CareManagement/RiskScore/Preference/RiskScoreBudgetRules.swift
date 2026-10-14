import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score budget must pass. Check returns its problems, or none.
    protocol RiskScoreBudgetRule {
        func check(_ item: RiskScoreBudget) -> [String]
    }

    final class RiskScoreBudgetGraceDaysRangeRule: RiskScoreBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreBudget) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreBudgetPatientRefLengthRule: RiskScoreBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreBudget) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreBudgetRequiredNameRule: RiskScoreBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreBudgetAllowedNameRule: RiskScoreBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score budget.
    final class RiskScoreBudgetValidator {
        var rules: [any RiskScoreBudgetRule]

        init(rules: [any RiskScoreBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreBudget]) -> [String: [String]] {
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

    static func defaultRiskScoreBudgetValidator() -> RiskScoreBudgetValidator {
        return RiskScoreBudgetValidator(
            rules: [
                RiskScoreBudgetGraceDaysRangeRule(min: 64, max: 1000),
                RiskScoreBudgetPatientRefLengthRule(maxLength: 32),
                RiskScoreBudgetRequiredNameRule(message: "risk score budget needs a value"),
                RiskScoreBudgetAllowedNameRule(allowed: ["capped", "capped", "pending"]),
            ]
        )
    }
}
