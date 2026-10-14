import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict skill mix audit must pass. Check returns its problems, or none.
    protocol StrictSkillMixAuditRule {
        func check(_ item: StrictSkillMixAudit) -> [String]
    }

    final class StrictSkillMixAuditWeightRangeRule: StrictSkillMixAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSkillMixAudit) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictSkillMixAuditRequiredReviewerRule: StrictSkillMixAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSkillMixAudit) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSkillMixAuditRequiredNameRule: StrictSkillMixAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSkillMixAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSkillMixAuditTagsLimitRule: StrictSkillMixAuditRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: StrictSkillMixAudit) -> [String] {
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

    /// Runs every rule of a strict skill mix audit.
    final class StrictSkillMixAuditValidator {
        var rules: [any StrictSkillMixAuditRule]

        init(rules: [any StrictSkillMixAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSkillMixAudit) -> [String] {
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

        func requireValid(_ item: StrictSkillMixAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSkillMixAudit]) -> [String: [String]] {
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

    static func defaultStrictSkillMixAuditValidator() -> StrictSkillMixAuditValidator {
        return StrictSkillMixAuditValidator(
            rules: [
                StrictSkillMixAuditWeightRangeRule(min: 8.2, max: 1248.4),
                StrictSkillMixAuditRequiredReviewerRule(message: "strict skill mix audit needs this field"),
                StrictSkillMixAuditRequiredNameRule(message: "strict skill mix audit needs this field"),
                StrictSkillMixAuditTagsLimitRule(maxCount: 86400, banned: ["pending", "regional"]),
            ]
        )
    }
}
