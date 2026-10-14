import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted acuity plan budget must pass. Check returns its problems, or none.
    protocol WeightedAcuityPlanBudgetRule {
        func check(_ item: WeightedAcuityPlanBudget) -> [String]
    }

    final class WeightedAcuityPlanBudgetRefillsRangeRule: WeightedAcuityPlanBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedAcuityPlanBudget) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedAcuityPlanBudgetRequiredContactEmailRule: WeightedAcuityPlanBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAcuityPlanBudget) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAcuityPlanBudgetPriorityRangeRule: WeightedAcuityPlanBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedAcuityPlanBudget) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedAcuityPlanBudgetAllowedCodeRule: WeightedAcuityPlanBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedAcuityPlanBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class WeightedAcuityPlanBudgetSegmentLengthRule: WeightedAcuityPlanBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAcuityPlanBudget) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAcuityPlanBudgetContactEmailLengthRule: WeightedAcuityPlanBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAcuityPlanBudget) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted acuity plan budget.
    final class WeightedAcuityPlanBudgetValidator {
        var rules: [any WeightedAcuityPlanBudgetRule]

        init(rules: [any WeightedAcuityPlanBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAcuityPlanBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedAcuityPlanBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAcuityPlanBudget]) -> [String: [String]] {
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

    static func defaultWeightedAcuityPlanBudgetValidator() -> WeightedAcuityPlanBudgetValidator {
        return WeightedAcuityPlanBudgetValidator(
            rules: [
                WeightedAcuityPlanBudgetRefillsRangeRule(min: 80, max: 255),
                WeightedAcuityPlanBudgetRequiredContactEmailRule(
                    message: "weighted acuity plan budget needs an entry"
                ),
                WeightedAcuityPlanBudgetPriorityRangeRule(min: 1000, max: 1000),
                WeightedAcuityPlanBudgetAllowedCodeRule(allowed: ["rolling", "adaptive"]),
                WeightedAcuityPlanBudgetSegmentLengthRule(maxLength: 3600),
                WeightedAcuityPlanBudgetContactEmailLengthRule(maxLength: 64),
            ]
        )
    }
}
