import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled authorization milestone must pass. Check returns its problems, or none.
    protocol ScheduledAuthorizationMilestoneRule {
        func check(_ item: ScheduledAuthorizationMilestone) -> [String]
    }

    final class ScheduledAuthorizationMilestoneRequiredNameRule: ScheduledAuthorizationMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAuthorizationMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAuthorizationMilestoneRequiredContactEmailRule: ScheduledAuthorizationMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAuthorizationMilestone) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAuthorizationMilestoneTagsLimitRule: ScheduledAuthorizationMilestoneRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ScheduledAuthorizationMilestone) -> [String] {
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

    final class ScheduledAuthorizationMilestoneAllowedReviewerRule: ScheduledAuthorizationMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledAuthorizationMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is out of range"]
            }
            return []
        }
    }

    final class ScheduledAuthorizationMilestoneNameLengthRule: ScheduledAuthorizationMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAuthorizationMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAuthorizationMilestoneCodePrefixRule: ScheduledAuthorizationMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledAuthorizationMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled authorization milestone.
    final class ScheduledAuthorizationMilestoneValidator {
        var rules: [any ScheduledAuthorizationMilestoneRule]

        init(rules: [any ScheduledAuthorizationMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAuthorizationMilestone) -> [String] {
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

        func requireValid(_ item: ScheduledAuthorizationMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAuthorizationMilestone]) -> [String: [String]] {
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

    static func defaultScheduledAuthorizationMilestoneValidator() -> ScheduledAuthorizationMilestoneValidator {
        return ScheduledAuthorizationMilestoneValidator(
            rules: [
                ScheduledAuthorizationMilestoneRequiredNameRule(
                    message: "scheduled authorization milestone needs a value"
                ),
                ScheduledAuthorizationMilestoneRequiredContactEmailRule(
                    message: "scheduled authorization milestone needs a value"
                ),
                ScheduledAuthorizationMilestoneTagsLimitRule(maxCount: 255, banned: ["global"]),
                ScheduledAuthorizationMilestoneAllowedReviewerRule(allowed: ["rolling", "tiered"]),
                ScheduledAuthorizationMilestoneNameLengthRule(maxLength: 80),
                ScheduledAuthorizationMilestoneCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
