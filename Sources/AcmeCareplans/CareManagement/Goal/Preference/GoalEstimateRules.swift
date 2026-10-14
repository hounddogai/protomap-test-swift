import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal estimate must pass. Check returns its problems, or none.
    protocol GoalEstimateRule {
        func check(_ item: GoalEstimate) -> [String]
    }

    final class GoalEstimateRequiredTitleRule: GoalEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalEstimateOwnerIDLengthRule: GoalEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalEstimate) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalEstimateAllowedTitleRule: GoalEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a goal estimate.
    final class GoalEstimateValidator {
        var rules: [any GoalEstimateRule]

        init(rules: [any GoalEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalEstimate]) -> [String: [String]] {
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

    static func defaultGoalEstimateValidator() -> GoalEstimateValidator {
        return GoalEstimateValidator(
            rules: [
                GoalEstimateRequiredTitleRule(message: "goal estimate needs an entry"),
                GoalEstimateOwnerIDLengthRule(maxLength: 32),
                GoalEstimateAllowedTitleRule(allowed: ["legacy"]),
            ]
        )
    }
}
