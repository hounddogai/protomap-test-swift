import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict specimen plan must pass. Check returns its problems, or none.
    protocol StrictSpecimenPlanRule {
        func check(_ item: StrictSpecimenPlan) -> [String]
    }

    final class StrictSpecimenPlanCopayRangeRule: StrictSpecimenPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSpecimenPlan) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictSpecimenPlanRequiredCodeRule: StrictSpecimenPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSpecimenPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSpecimenPlanRequiredDescriptionRule: StrictSpecimenPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSpecimenPlan) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSpecimenPlanCeilingRangeRule: StrictSpecimenPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSpecimenPlan) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict specimen plan.
    final class StrictSpecimenPlanValidator {
        var rules: [any StrictSpecimenPlanRule]

        init(rules: [any StrictSpecimenPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSpecimenPlan) -> [String] {
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

        func requireValid(_ item: StrictSpecimenPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSpecimenPlan]) -> [String: [String]] {
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

    static func defaultStrictSpecimenPlanValidator() -> StrictSpecimenPlanValidator {
        return StrictSpecimenPlanValidator(
            rules: [
                StrictSpecimenPlanCopayRangeRule(min: 8.8, max: 2819.1),
                StrictSpecimenPlanRequiredCodeRule(message: "strict specimen plan needs an entry"),
                StrictSpecimenPlanRequiredDescriptionRule(message: "strict specimen plan needs an entry"),
                StrictSpecimenPlanCeilingRangeRule(min: 5.8, max: 1429.4),
            ]
        )
    }
}
