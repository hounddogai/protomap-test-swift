import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal claim must pass. Check returns its problems, or none.
    protocol GoalClaimRule {
        func check(_ item: GoalClaim) -> [String]
    }

    final class GoalClaimRequiredCodeRule: GoalClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalClaimNameLengthRule: GoalClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalClaimCodeLengthRule: GoalClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalClaimBatchSizeRangeRule: GoalClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalClaim) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalClaimCodePrefixRule: GoalClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalClaimBudgetRangeRule: GoalClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalClaim) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a goal claim.
    final class GoalClaimValidator {
        var rules: [any GoalClaimRule]

        init(rules: [any GoalClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalClaim) -> [String] {
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

        func requireValid(_ item: GoalClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalClaim]) -> [String: [String]] {
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

    static func defaultGoalClaimValidator() -> GoalClaimValidator {
        return GoalClaimValidator(
            rules: [
                GoalClaimRequiredCodeRule(message: "goal claim needs this field"),
                GoalClaimNameLengthRule(maxLength: 120),
                GoalClaimCodeLengthRule(maxLength: 80),
                GoalClaimBatchSizeRangeRule(min: 80, max: 3600),
                GoalClaimCodePrefixRule(prefix: "REF"),
                GoalClaimBudgetRangeRule(min: 2.7, max: 853.3),
            ]
        )
    }
}
