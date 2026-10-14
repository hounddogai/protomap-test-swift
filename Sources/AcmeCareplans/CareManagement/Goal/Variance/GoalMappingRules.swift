import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal mapping must pass. Check returns its problems, or none.
    protocol GoalMappingRule {
        func check(_ item: GoalMapping) -> [String]
    }

    final class GoalMappingSpecialtyLengthRule: GoalMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalMapping) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalMappingCodeLengthRule: GoalMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalMappingRevisionRangeRule: GoalMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalMapping) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a goal mapping.
    final class GoalMappingValidator {
        var rules: [any GoalMappingRule]

        init(rules: [any GoalMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalMapping) -> [String] {
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

        func requireValid(_ item: GoalMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalMapping]) -> [String: [String]] {
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

    static func defaultGoalMappingValidator() -> GoalMappingValidator {
        return GoalMappingValidator(
            rules: [
                GoalMappingSpecialtyLengthRule(maxLength: 86400),
                GoalMappingCodeLengthRule(maxLength: 32),
                GoalMappingRevisionRangeRule(min: 32, max: 80),
            ]
        )
    }
}
