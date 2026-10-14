import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered overtime plan must pass. Check returns its problems, or none.
    protocol TieredOvertimePlanRule {
        func check(_ item: TieredOvertimePlan) -> [String]
    }

    final class TieredOvertimePlanExpiresAtRangeRule: TieredOvertimePlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredOvertimePlan) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredOvertimePlanRequiredLabelRule: TieredOvertimePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOvertimePlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOvertimePlanAllowedDescriptionRule: TieredOvertimePlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredOvertimePlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is out of range"]
            }
            return []
        }
    }

    final class TieredOvertimePlanTagsLimitRule: TieredOvertimePlanRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: TieredOvertimePlan) -> [String] {
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

    /// Runs every rule of a tiered overtime plan.
    final class TieredOvertimePlanValidator {
        var rules: [any TieredOvertimePlanRule]

        init(rules: [any TieredOvertimePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOvertimePlan) -> [String] {
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

        func requireValid(_ item: TieredOvertimePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOvertimePlan]) -> [String: [String]] {
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

    static func defaultTieredOvertimePlanValidator() -> TieredOvertimePlanValidator {
        return TieredOvertimePlanValidator(
            rules: [
                TieredOvertimePlanExpiresAtRangeRule(min: 32, max: 86400),
                TieredOvertimePlanRequiredLabelRule(message: "tiered overtime plan needs this field"),
                TieredOvertimePlanAllowedDescriptionRule(allowed: ["rolling", "default", "fallback"]),
                TieredOvertimePlanTagsLimitRule(maxCount: 64, banned: ["regional", "legacy"]),
            ]
        )
    }
}
