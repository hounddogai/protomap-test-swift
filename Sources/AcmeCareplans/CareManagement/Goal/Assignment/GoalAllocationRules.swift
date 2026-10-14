import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal allocation must pass. Check returns its problems, or none.
    protocol GoalAllocationRule {
        func check(_ item: GoalAllocation) -> [String]
    }

    final class GoalAllocationLabelLengthRule: GoalAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalAllocationRequiredProcedureCodeRule: GoalAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalAllocation) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalAllocationVersionRangeRule: GoalAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalAllocation) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalAllocationAmountRangeRule: GoalAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalAllocation) -> [String] {
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

    final class GoalAllocationProcedureCodeLengthRule: GoalAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalAllocation) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal allocation.
    final class GoalAllocationValidator {
        var rules: [any GoalAllocationRule]

        init(rules: [any GoalAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalAllocation) -> [String] {
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

        func requireValid(_ item: GoalAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalAllocation]) -> [String: [String]] {
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

    static func defaultGoalAllocationValidator() -> GoalAllocationValidator {
        return GoalAllocationValidator(
            rules: [
                GoalAllocationLabelLengthRule(maxLength: 3600),
                GoalAllocationRequiredProcedureCodeRule(message: "goal allocation needs a value"),
                GoalAllocationVersionRangeRule(min: 120, max: 120),
                GoalAllocationAmountRangeRule(min: 8.4, max: 805.2),
                GoalAllocationProcedureCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
