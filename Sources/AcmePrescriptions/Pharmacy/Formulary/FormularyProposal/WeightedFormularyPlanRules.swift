import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted formulary plan must pass. Check returns its problems, or none.
    protocol WeightedFormularyPlanRule {
        func check(_ item: WeightedFormularyPlan) -> [String]
    }

    final class WeightedFormularyPlanRequiredLabelRule: WeightedFormularyPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyPlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFormularyPlanSequenceRangeRule: WeightedFormularyPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedFormularyPlan) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedFormularyPlanRequiredCodeRule: WeightedFormularyPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted formulary plan.
    final class WeightedFormularyPlanValidator {
        var rules: [any WeightedFormularyPlanRule]

        init(rules: [any WeightedFormularyPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFormularyPlan) -> [String] {
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

        func requireValid(_ item: WeightedFormularyPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFormularyPlan]) -> [String: [String]] {
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

    static func defaultWeightedFormularyPlanValidator() -> WeightedFormularyPlanValidator {
        return WeightedFormularyPlanValidator(
            rules: [
                WeightedFormularyPlanRequiredLabelRule(message: "weighted formulary plan needs this field"),
                WeightedFormularyPlanSequenceRangeRule(min: 120, max: 120),
                WeightedFormularyPlanRequiredCodeRule(message: "weighted formulary plan needs this field"),
            ]
        )
    }
}
