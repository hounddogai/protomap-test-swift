import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy summary must pass. Check returns its problems, or none.
    protocol ProxySummaryRule {
        func check(_ item: ProxySummary) -> [String]
    }

    final class ProxySummaryTagsLimitRule: ProxySummaryRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ProxySummary) -> [String] {
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

    final class ProxySummaryCeilingRangeRule: ProxySummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxySummary) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxySummaryLabelLengthRule: ProxySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxySummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxySummaryCodePrefixRule: ProxySummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxySummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxySummaryAllowedReviewerRule: ProxySummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxySummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is not allowed"]
            }
            return []
        }
    }

    final class ProxySummaryCopayRangeRule: ProxySummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxySummary) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy summary.
    final class ProxySummaryValidator {
        var rules: [any ProxySummaryRule]

        init(rules: [any ProxySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxySummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxySummary]) -> [String: [String]] {
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

    static func defaultProxySummaryValidator() -> ProxySummaryValidator {
        return ProxySummaryValidator(
            rules: [
                ProxySummaryTagsLimitRule(maxCount: 64, banned: ["seasonal"]),
                ProxySummaryCeilingRangeRule(min: 3.5, max: 1687.7),
                ProxySummaryLabelLengthRule(maxLength: 80),
                ProxySummaryCodePrefixRule(prefix: "X"),
                ProxySummaryAllowedReviewerRule(allowed: ["default", "fallback", "primary"]),
                ProxySummaryCopayRangeRule(min: 0.9, max: 3582.9),
            ]
        )
    }
}
