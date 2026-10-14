import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff digest must pass. Check returns its problems, or none.
    protocol HandoffDigestRule {
        func check(_ item: HandoffDigest) -> [String]
    }

    final class HandoffDigestEndsAtRangeRule: HandoffDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffDigest) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class HandoffDigestChannelLengthRule: HandoffDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffDigest) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffDigestExpiresAtRangeRule: HandoffDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffDigest) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffDigestTagsLimitRule: HandoffDigestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: HandoffDigest) -> [String] {
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

    /// Runs every rule of a handoff digest.
    final class HandoffDigestValidator {
        var rules: [any HandoffDigestRule]

        init(rules: [any HandoffDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffDigest) -> [String] {
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

        func requireValid(_ item: HandoffDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffDigest]) -> [String: [String]] {
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

    static func defaultHandoffDigestValidator() -> HandoffDigestValidator {
        return HandoffDigestValidator(
            rules: [
                HandoffDigestEndsAtRangeRule(min: 80, max: 86400),
                HandoffDigestChannelLengthRule(maxLength: 64),
                HandoffDigestExpiresAtRangeRule(min: 64, max: 80),
                HandoffDigestTagsLimitRule(maxCount: 3600, banned: ["seasonal"]),
            ]
        )
    }
}
