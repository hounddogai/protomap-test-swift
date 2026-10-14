import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal score must pass. Check returns its problems, or none.
    protocol GoalScoreRule {
        func check(_ item: GoalScore) -> [String]
    }

    final class GoalScoreRequiredContactEmailRule: GoalScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalScore) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalScoreRequiredNameRule: GoalScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalScoreCodePrefixRule: GoalScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalScoreWeightRangeRule: GoalScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalScore) -> [String] {
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

    final class GoalScoreAllowedContactEmailRule: GoalScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is not allowed"]
            }
            return []
        }
    }

    final class GoalScoreVisitMinutesRangeRule: GoalScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalScore) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a goal score.
    final class GoalScoreValidator {
        var rules: [any GoalScoreRule]

        init(rules: [any GoalScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalScore) -> [String] {
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

        func requireValid(_ item: GoalScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalScore]) -> [String: [String]] {
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

    static func defaultGoalScoreValidator() -> GoalScoreValidator {
        return GoalScoreValidator(
            rules: [
                GoalScoreRequiredContactEmailRule(message: "goal score needs an entry"),
                GoalScoreRequiredNameRule(message: "goal score needs this field"),
                GoalScoreCodePrefixRule(prefix: "ACM"),
                GoalScoreWeightRangeRule(min: 9.5, max: 3418.0),
                GoalScoreAllowedContactEmailRule(allowed: ["fallback", "regional", "strict"]),
                GoalScoreVisitMinutesRangeRule(min: 16, max: 16),
            ]
        )
    }
}
