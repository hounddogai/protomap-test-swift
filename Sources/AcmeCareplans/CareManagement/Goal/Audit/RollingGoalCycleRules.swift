import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling goal cycle must pass. Check returns its problems, or none.
    protocol RollingGoalCycleRule {
        func check(_ item: RollingGoalCycle) -> [String]
    }

    final class RollingGoalCycleExternalRefLengthRule: RollingGoalCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingGoalCycle) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingGoalCycleAllowedExternalRefRule: RollingGoalCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingGoalCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is too long"]
            }
            return []
        }
    }

    final class RollingGoalCycleThresholdRangeRule: RollingGoalCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingGoalCycle) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingGoalCycleTitleLengthRule: RollingGoalCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingGoalCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingGoalCycleTagsLimitRule: RollingGoalCycleRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RollingGoalCycle) -> [String] {
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

    final class RollingGoalCycleCodePrefixRule: RollingGoalCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingGoalCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling goal cycle.
    final class RollingGoalCycleValidator {
        var rules: [any RollingGoalCycleRule]

        init(rules: [any RollingGoalCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingGoalCycle) -> [String] {
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

        func requireValid(_ item: RollingGoalCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingGoalCycle]) -> [String: [String]] {
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

    static func defaultRollingGoalCycleValidator() -> RollingGoalCycleValidator {
        return RollingGoalCycleValidator(
            rules: [
                RollingGoalCycleExternalRefLengthRule(maxLength: 32),
                RollingGoalCycleAllowedExternalRefRule(allowed: ["pending"]),
                RollingGoalCycleThresholdRangeRule(min: 0.6, max: 1261.8),
                RollingGoalCycleTitleLengthRule(maxLength: 32),
                RollingGoalCycleTagsLimitRule(maxCount: 255, banned: []),
                RollingGoalCycleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
