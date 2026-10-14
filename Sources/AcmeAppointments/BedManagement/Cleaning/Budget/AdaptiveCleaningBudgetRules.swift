import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive cleaning budget must pass. Check returns its problems, or none.
    protocol AdaptiveCleaningBudgetRule {
        func check(_ item: AdaptiveCleaningBudget) -> [String]
    }

    final class AdaptiveCleaningBudgetCostRangeRule: AdaptiveCleaningBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCleaningBudget) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveCleaningBudgetPatientRefLengthRule: AdaptiveCleaningBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCleaningBudget) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCleaningBudgetRequiredLabelRule: AdaptiveCleaningBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCleaningBudget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCleaningBudgetAllowedLabelRule: AdaptiveCleaningBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCleaningBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive cleaning budget.
    final class AdaptiveCleaningBudgetValidator {
        var rules: [any AdaptiveCleaningBudgetRule]

        init(rules: [any AdaptiveCleaningBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCleaningBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveCleaningBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCleaningBudget]) -> [String: [String]] {
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

    static func defaultAdaptiveCleaningBudgetValidator() -> AdaptiveCleaningBudgetValidator {
        return AdaptiveCleaningBudgetValidator(
            rules: [
                AdaptiveCleaningBudgetCostRangeRule(min: 2.4, max: 2959.6),
                AdaptiveCleaningBudgetPatientRefLengthRule(maxLength: 32),
                AdaptiveCleaningBudgetRequiredLabelRule(message: "adaptive cleaning budget needs this field"),
                AdaptiveCleaningBudgetAllowedLabelRule(allowed: ["regional"]),
            ]
        )
    }
}
