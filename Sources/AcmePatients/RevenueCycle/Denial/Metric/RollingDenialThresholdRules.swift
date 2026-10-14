import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling denial threshold must pass. Check returns its problems, or none.
    protocol RollingDenialThresholdRule {
        func check(_ item: RollingDenialThreshold) -> [String]
    }

    final class RollingDenialThresholdTagsLimitRule: RollingDenialThresholdRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RollingDenialThreshold) -> [String] {
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

    final class RollingDenialThresholdCodeLengthRule: RollingDenialThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDenialThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDenialThresholdRequiredCodeRule: RollingDenialThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDenialThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDenialThresholdSourceLengthRule: RollingDenialThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDenialThreshold) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDenialThresholdTitleLengthRule: RollingDenialThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDenialThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling denial threshold.
    final class RollingDenialThresholdValidator {
        var rules: [any RollingDenialThresholdRule]

        init(rules: [any RollingDenialThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDenialThreshold) -> [String] {
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

        func requireValid(_ item: RollingDenialThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDenialThreshold]) -> [String: [String]] {
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

    static func defaultRollingDenialThresholdValidator() -> RollingDenialThresholdValidator {
        return RollingDenialThresholdValidator(
            rules: [
                RollingDenialThresholdTagsLimitRule(maxCount: 3600, banned: ["capped"]),
                RollingDenialThresholdCodeLengthRule(maxLength: 16),
                RollingDenialThresholdRequiredCodeRule(message: "rolling denial threshold needs this field"),
                RollingDenialThresholdSourceLengthRule(maxLength: 16),
                RollingDenialThresholdTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
