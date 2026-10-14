import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal preference must pass. Check returns its problems, or none.
    protocol GoalPreferenceRule {
        func check(_ item: GoalPreference) -> [String]
    }

    final class GoalPreferenceRequiredCodeRule: GoalPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalPreferenceSourceLengthRule: GoalPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalPreference) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalPreferenceCodePrefixRule: GoalPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalPreferenceRequiredTitleRule: GoalPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalPreferenceTagsLimitRule: GoalPreferenceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: GoalPreference) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a goal preference.
    final class GoalPreferenceValidator {
        var rules: [any GoalPreferenceRule]

        init(rules: [any GoalPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalPreference]) -> [String: [String]] {
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

    static func defaultGoalPreferenceValidator() -> GoalPreferenceValidator {
        return GoalPreferenceValidator(
            rules: [
                GoalPreferenceRequiredCodeRule(message: "goal preference needs a value"),
                GoalPreferenceSourceLengthRule(maxLength: 16),
                GoalPreferenceCodePrefixRule(prefix: "X"),
                GoalPreferenceRequiredTitleRule(message: "goal preference needs this field"),
                GoalPreferenceTagsLimitRule(maxCount: 255, banned: ["rolling", "global", "fallback"]),
            ]
        )
    }
}
