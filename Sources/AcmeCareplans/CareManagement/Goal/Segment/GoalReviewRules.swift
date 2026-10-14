import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal review must pass. Check returns its problems, or none.
    protocol GoalReviewRule {
        func check(_ item: GoalReview) -> [String]
    }

    final class GoalReviewArchivedGuardRule: GoalReviewRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GoalReview) -> [String] {
            if item.archived && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class GoalReviewRequiredCodeRule: GoalReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalReviewRevisionRangeRule: GoalReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalReview) -> [String] {
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

    /// Runs every rule of a goal review.
    final class GoalReviewValidator {
        var rules: [any GoalReviewRule]

        init(rules: [any GoalReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalReview]) -> [String: [String]] {
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

    static func defaultGoalReviewValidator() -> GoalReviewValidator {
        return GoalReviewValidator(
            rules: [
                GoalReviewArchivedGuardRule(limit: 3600),
                GoalReviewRequiredCodeRule(message: "goal review needs this field"),
                GoalReviewRevisionRangeRule(min: 255, max: 255),
            ]
        )
    }
}
