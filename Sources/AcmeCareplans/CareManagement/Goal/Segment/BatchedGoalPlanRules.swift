import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched goal plan must pass. Check returns its problems, or none.
    protocol BatchedGoalPlanRule {
        func check(_ item: BatchedGoalPlan) -> [String]
    }

    final class BatchedGoalPlanAllowedNameRule: BatchedGoalPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedGoalPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class BatchedGoalPlanRequiredNotesRule: BatchedGoalPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedGoalPlan) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedGoalPlanStartsAtRangeRule: BatchedGoalPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedGoalPlan) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedGoalPlanOwnerIDLengthRule: BatchedGoalPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedGoalPlan) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedGoalPlanNameLengthRule: BatchedGoalPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedGoalPlan) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched goal plan.
    final class BatchedGoalPlanValidator {
        var rules: [any BatchedGoalPlanRule]

        init(rules: [any BatchedGoalPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedGoalPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedGoalPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedGoalPlan]) -> [String: [String]] {
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

    static func defaultBatchedGoalPlanValidator() -> BatchedGoalPlanValidator {
        return BatchedGoalPlanValidator(
            rules: [
                BatchedGoalPlanAllowedNameRule(allowed: ["weighted", "batched"]),
                BatchedGoalPlanRequiredNotesRule(message: "batched goal plan needs this field"),
                BatchedGoalPlanStartsAtRangeRule(min: 16, max: 86400),
                BatchedGoalPlanOwnerIDLengthRule(maxLength: 1000),
                BatchedGoalPlanNameLengthRule(maxLength: 255),
            ]
        )
    }
}
