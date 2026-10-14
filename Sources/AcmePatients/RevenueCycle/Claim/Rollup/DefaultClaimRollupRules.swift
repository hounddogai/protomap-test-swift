import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default claim rollup must pass. Check returns its problems, or none.
    protocol DefaultClaimRollupRule {
        func check(_ item: DefaultClaimRollup) -> [String]
    }

    final class DefaultClaimRollupTagsLimitRule: DefaultClaimRollupRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: DefaultClaimRollup) -> [String] {
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

    final class DefaultClaimRollupRequiredCategoryRule: DefaultClaimRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultClaimRollup) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultClaimRollupRevisionRangeRule: DefaultClaimRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultClaimRollup) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultClaimRollupAllowedCategoryRule: DefaultClaimRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultClaimRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is blocked"]
            }
            return []
        }
    }

    final class DefaultClaimRollupCodePrefixRule: DefaultClaimRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultClaimRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultClaimRollupRequiredTitleRule: DefaultClaimRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultClaimRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default claim rollup.
    final class DefaultClaimRollupValidator {
        var rules: [any DefaultClaimRollupRule]

        init(rules: [any DefaultClaimRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultClaimRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultClaimRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultClaimRollup]) -> [String: [String]] {
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

    static func defaultDefaultClaimRollupValidator() -> DefaultClaimRollupValidator {
        return DefaultClaimRollupValidator(
            rules: [
                DefaultClaimRollupTagsLimitRule(maxCount: 16, banned: ["manual"]),
                DefaultClaimRollupRequiredCategoryRule(message: "default claim rollup needs a value"),
                DefaultClaimRollupRevisionRangeRule(min: 120, max: 1000),
                DefaultClaimRollupAllowedCategoryRule(allowed: ["scheduled", "rolling", "adaptive"]),
                DefaultClaimRollupCodePrefixRule(prefix: "X"),
                DefaultClaimRollupRequiredTitleRule(message: "default claim rollup needs a value"),
            ]
        )
    }
}
