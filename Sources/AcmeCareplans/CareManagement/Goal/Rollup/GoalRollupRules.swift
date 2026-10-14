import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal rollup must pass. Check returns its problems, or none.
    protocol GoalRollupRule {
        func check(_ item: GoalRollup) -> [String]
    }

    final class GoalRollupClinicianIDLengthRule: GoalRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalRollup) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalRollupAllowedChecksumRule: GoalRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is inconsistent"]
            }
            return []
        }
    }

    final class GoalRollupTagsLimitRule: GoalRollupRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: GoalRollup) -> [String] {
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

    final class GoalRollupChecksumLengthRule: GoalRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalRollup) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal rollup.
    final class GoalRollupValidator {
        var rules: [any GoalRollupRule]

        init(rules: [any GoalRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalRollup]) -> [String: [String]] {
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

    static func defaultGoalRollupValidator() -> GoalRollupValidator {
        return GoalRollupValidator(
            rules: [
                GoalRollupClinicianIDLengthRule(maxLength: 32),
                GoalRollupAllowedChecksumRule(allowed: ["regional", "legacy", "seasonal"]),
                GoalRollupTagsLimitRule(maxCount: 32, banned: ["lenient", "rolling"]),
                GoalRollupChecksumLengthRule(maxLength: 255),
            ]
        )
    }
}
