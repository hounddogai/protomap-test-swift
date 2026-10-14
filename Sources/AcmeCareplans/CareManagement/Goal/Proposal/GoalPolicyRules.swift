import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal policy must pass. Check returns its problems, or none.
    protocol GoalPolicyRule {
        func check(_ item: GoalPolicy) -> [String]
    }

    final class GoalPolicyAllowedCountryRule: GoalPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is expired"]
            }
            return []
        }
    }

    final class GoalPolicyLabelLengthRule: GoalPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalPolicyRequiredReviewerRule: GoalPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalPolicy) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalPolicyCodeLengthRule: GoalPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal policy.
    final class GoalPolicyValidator {
        var rules: [any GoalPolicyRule]

        init(rules: [any GoalPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalPolicy) -> [String] {
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

        func requireValid(_ item: GoalPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalPolicy]) -> [String: [String]] {
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

    static func defaultGoalPolicyValidator() -> GoalPolicyValidator {
        return GoalPolicyValidator(
            rules: [
                GoalPolicyAllowedCountryRule(allowed: ["batched", "rolling", "legacy"]),
                GoalPolicyLabelLengthRule(maxLength: 3600),
                GoalPolicyRequiredReviewerRule(message: "goal policy needs an entry"),
                GoalPolicyCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
