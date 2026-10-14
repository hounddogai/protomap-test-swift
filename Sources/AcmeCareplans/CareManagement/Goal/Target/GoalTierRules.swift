import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal tier must pass. Check returns its problems, or none.
    protocol GoalTierRule {
        func check(_ item: GoalTier) -> [String]
    }

    final class GoalTierCodePrefixRule: GoalTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalTierTimezoneLengthRule: GoalTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalTier) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalTierCapacityRangeRule: GoalTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalTier) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GoalTierRequiredLabelRule: GoalTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal tier.
    final class GoalTierValidator {
        var rules: [any GoalTierRule]

        init(rules: [any GoalTierRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalTier) -> [String] {
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

        func requireValid(_ item: GoalTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalTier]) -> [String: [String]] {
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

    static func defaultGoalTierValidator() -> GoalTierValidator {
        return GoalTierValidator(
            rules: [
                GoalTierCodePrefixRule(prefix: "ACM"),
                GoalTierTimezoneLengthRule(maxLength: 64),
                GoalTierCapacityRangeRule(min: 80, max: 120),
                GoalTierRequiredLabelRule(message: "goal tier needs this field"),
            ]
        )
    }
}
