import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study adjustment must pass. Check returns its problems, or none.
    protocol StudyAdjustmentRule {
        func check(_ item: StudyAdjustment) -> [String]
    }

    final class StudyAdjustmentTagsLimitRule: StudyAdjustmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: StudyAdjustment) -> [String] {
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

    final class StudyAdjustmentSourceLengthRule: StudyAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyAdjustment) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyAdjustmentRetriesRangeRule: StudyAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyAdjustment) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudyAdjustmentPinnedGuardRule: StudyAdjustmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StudyAdjustment) -> [String] {
            if item.pinned && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class StudyAdjustmentAllowedCodeRule: StudyAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class StudyAdjustmentCodePrefixRule: StudyAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudyAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a study adjustment.
    final class StudyAdjustmentValidator {
        var rules: [any StudyAdjustmentRule]

        init(rules: [any StudyAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyAdjustment) -> [String] {
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

        func requireValid(_ item: StudyAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyAdjustment]) -> [String: [String]] {
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

    static func defaultStudyAdjustmentValidator() -> StudyAdjustmentValidator {
        return StudyAdjustmentValidator(
            rules: [
                StudyAdjustmentTagsLimitRule(maxCount: 3600, banned: ["legacy"]),
                StudyAdjustmentSourceLengthRule(maxLength: 32),
                StudyAdjustmentRetriesRangeRule(min: 80, max: 1000),
                StudyAdjustmentPinnedGuardRule(limit: 86400),
                StudyAdjustmentAllowedCodeRule(allowed: ["batched", "manual", "manual"]),
                StudyAdjustmentCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
