import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched language threshold must pass. Check returns its problems, or none.
    protocol BatchedLanguageThresholdRule {
        func check(_ item: BatchedLanguageThreshold) -> [String]
    }

    final class BatchedLanguageThresholdCodePrefixRule: BatchedLanguageThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedLanguageThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedLanguageThresholdUpdatedAtRangeRule: BatchedLanguageThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedLanguageThreshold) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedLanguageThresholdPinnedGuardRule: BatchedLanguageThresholdRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedLanguageThreshold) -> [String] {
            if item.pinned && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class BatchedLanguageThresholdTagsLimitRule: BatchedLanguageThresholdRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: BatchedLanguageThreshold) -> [String] {
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

    final class BatchedLanguageThresholdVersionRangeRule: BatchedLanguageThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedLanguageThreshold) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched language threshold.
    final class BatchedLanguageThresholdValidator {
        var rules: [any BatchedLanguageThresholdRule]

        init(rules: [any BatchedLanguageThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedLanguageThreshold) -> [String] {
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

        func requireValid(_ item: BatchedLanguageThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedLanguageThreshold]) -> [String: [String]] {
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

    static func defaultBatchedLanguageThresholdValidator() -> BatchedLanguageThresholdValidator {
        return BatchedLanguageThresholdValidator(
            rules: [
                BatchedLanguageThresholdCodePrefixRule(prefix: "REF"),
                BatchedLanguageThresholdUpdatedAtRangeRule(min: 120, max: 255),
                BatchedLanguageThresholdPinnedGuardRule(limit: 1000),
                BatchedLanguageThresholdTagsLimitRule(maxCount: 32, banned: []),
                BatchedLanguageThresholdVersionRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
