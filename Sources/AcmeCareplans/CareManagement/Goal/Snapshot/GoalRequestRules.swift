import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal request must pass. Check returns its problems, or none.
    protocol GoalRequestRule {
        func check(_ item: GoalRequest) -> [String]
    }

    final class GoalRequestTagsLimitRule: GoalRequestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: GoalRequest) -> [String] {
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

    final class GoalRequestAllowedCodeRule: GoalRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class GoalRequestLabelLengthRule: GoalRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalRequestRequiredSummaryRule: GoalRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalRequest) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalRequestCodePrefixRule: GoalRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalRequestRequiredLabelRule: GoalRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal request.
    final class GoalRequestValidator {
        var rules: [any GoalRequestRule]

        init(rules: [any GoalRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalRequest]) -> [String: [String]] {
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

    static func defaultGoalRequestValidator() -> GoalRequestValidator {
        return GoalRequestValidator(
            rules: [
                GoalRequestTagsLimitRule(maxCount: 1000, banned: []),
                GoalRequestAllowedCodeRule(allowed: []),
                GoalRequestLabelLengthRule(maxLength: 80),
                GoalRequestRequiredSummaryRule(message: "goal request needs this field"),
                GoalRequestCodePrefixRule(prefix: "X"),
                GoalRequestRequiredLabelRule(message: "goal request needs an entry"),
            ]
        )
    }
}
