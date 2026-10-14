import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending handoff plan must pass. Check returns its problems, or none.
    protocol PendingHandoffPlanRule {
        func check(_ item: PendingHandoffPlan) -> [String]
    }

    final class PendingHandoffPlanWeightRangeRule: PendingHandoffPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingHandoffPlan) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingHandoffPlanPriorityRangeRule: PendingHandoffPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingHandoffPlan) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingHandoffPlanAmountRangeRule: PendingHandoffPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingHandoffPlan) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingHandoffPlanReviewerLengthRule: PendingHandoffPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingHandoffPlan) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingHandoffPlanUpdatedAtRangeRule: PendingHandoffPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingHandoffPlan) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending handoff plan.
    final class PendingHandoffPlanValidator {
        var rules: [any PendingHandoffPlanRule]

        init(rules: [any PendingHandoffPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingHandoffPlan) -> [String] {
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

        func requireValid(_ item: PendingHandoffPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingHandoffPlan]) -> [String: [String]] {
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

    static func defaultPendingHandoffPlanValidator() -> PendingHandoffPlanValidator {
        return PendingHandoffPlanValidator(
            rules: [
                PendingHandoffPlanWeightRangeRule(min: 4.0, max: 2021.1),
                PendingHandoffPlanPriorityRangeRule(min: 16, max: 255),
                PendingHandoffPlanAmountRangeRule(min: 6.5, max: 1535.9),
                PendingHandoffPlanReviewerLengthRule(maxLength: 32),
                PendingHandoffPlanUpdatedAtRangeRule(min: 32, max: 64),
            ]
        )
    }
}
