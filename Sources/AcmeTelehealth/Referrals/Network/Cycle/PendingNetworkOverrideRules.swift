import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending network override must pass. Check returns its problems, or none.
    protocol PendingNetworkOverrideRule {
        func check(_ item: PendingNetworkOverride) -> [String]
    }

    final class PendingNetworkOverrideMaximumRangeRule: PendingNetworkOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingNetworkOverride) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingNetworkOverrideTagsLimitRule: PendingNetworkOverrideRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: PendingNetworkOverride) -> [String] {
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

    final class PendingNetworkOverrideRequiredCodeRule: PendingNetworkOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingNetworkOverridePriorityRangeRule: PendingNetworkOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingNetworkOverride) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingNetworkOverrideRequiredRegionRule: PendingNetworkOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkOverride) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingNetworkOverrideLimitRangeRule: PendingNetworkOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingNetworkOverride) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending network override.
    final class PendingNetworkOverrideValidator {
        var rules: [any PendingNetworkOverrideRule]

        init(rules: [any PendingNetworkOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingNetworkOverride) -> [String] {
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

        func requireValid(_ item: PendingNetworkOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingNetworkOverride]) -> [String: [String]] {
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

    static func defaultPendingNetworkOverrideValidator() -> PendingNetworkOverrideValidator {
        return PendingNetworkOverrideValidator(
            rules: [
                PendingNetworkOverrideMaximumRangeRule(min: 1.6, max: 3336.3),
                PendingNetworkOverrideTagsLimitRule(maxCount: 86400, banned: ["legacy", "legacy"]),
                PendingNetworkOverrideRequiredCodeRule(message: "pending network override needs this field"),
                PendingNetworkOverridePriorityRangeRule(min: 120, max: 1000),
                PendingNetworkOverrideRequiredRegionRule(message: "pending network override needs an entry"),
                PendingNetworkOverrideLimitRangeRule(min: 64, max: 255),
            ]
        )
    }
}
