import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling modality audit must pass. Check returns its problems, or none.
    protocol RollingModalityAuditRule {
        func check(_ item: RollingModalityAudit) -> [String]
    }

    final class RollingModalityAuditTagsLimitRule: RollingModalityAuditRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RollingModalityAudit) -> [String] {
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

    final class RollingModalityAuditPriorityRangeRule: RollingModalityAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingModalityAudit) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingModalityAuditCodePrefixRule: RollingModalityAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingModalityAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling modality audit.
    final class RollingModalityAuditValidator {
        var rules: [any RollingModalityAuditRule]

        init(rules: [any RollingModalityAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingModalityAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingModalityAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingModalityAudit]) -> [String: [String]] {
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

    static func defaultRollingModalityAuditValidator() -> RollingModalityAuditValidator {
        return RollingModalityAuditValidator(
            rules: [
                RollingModalityAuditTagsLimitRule(maxCount: 1000, banned: ["scheduled"]),
                RollingModalityAuditPriorityRangeRule(min: 16, max: 80),
                RollingModalityAuditCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
