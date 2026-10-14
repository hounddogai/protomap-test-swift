import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority plan must pass. Check returns its problems, or none.
    protocol PriorityPlanRule {
        func check(_ item: PriorityPlan) -> [String]
    }

    final class PriorityPlanRequiredCodeRule: PriorityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityPlanCostRangeRule: PriorityPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityPlan) -> [String] {
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

    final class PriorityPlanNameLengthRule: PriorityPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityPlan) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityPlanThresholdRangeRule: PriorityPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityPlan) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityPlanArchivedGuardRule: PriorityPlanRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PriorityPlan) -> [String] {
            if item.archived && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a priority plan.
    final class PriorityPlanValidator {
        var rules: [any PriorityPlanRule]

        init(rules: [any PriorityPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityPlan]) -> [String: [String]] {
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

    static func defaultPriorityPlanValidator() -> PriorityPlanValidator {
        return PriorityPlanValidator(
            rules: [
                PriorityPlanRequiredCodeRule(message: "priority plan needs an entry"),
                PriorityPlanCostRangeRule(min: 3.9, max: 2344.8),
                PriorityPlanNameLengthRule(maxLength: 1000),
                PriorityPlanThresholdRangeRule(min: 0.7, max: 1449.2),
                PriorityPlanArchivedGuardRule(limit: 2.2),
            ]
        )
    }
}
