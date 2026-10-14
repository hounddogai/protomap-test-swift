import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback panel digest must pass. Check returns its problems, or none.
    protocol FallbackPanelDigestRule {
        func check(_ item: FallbackPanelDigest) -> [String]
    }

    final class FallbackPanelDigestTagsLimitRule: FallbackPanelDigestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FallbackPanelDigest) -> [String] {
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

    final class FallbackPanelDigestDosageMgRangeRule: FallbackPanelDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackPanelDigest) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackPanelDigestRequiredCategoryRule: FallbackPanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelDigest) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPanelDigestRateRangeRule: FallbackPanelDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackPanelDigest) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackPanelDigestRequiredLocaleRule: FallbackPanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelDigest) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPanelDigestRequiredTitleRule: FallbackPanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback panel digest.
    final class FallbackPanelDigestValidator {
        var rules: [any FallbackPanelDigestRule]

        init(rules: [any FallbackPanelDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackPanelDigest) -> [String] {
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

        func requireValid(_ item: FallbackPanelDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackPanelDigest]) -> [String: [String]] {
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

    static func defaultFallbackPanelDigestValidator() -> FallbackPanelDigestValidator {
        return FallbackPanelDigestValidator(
            rules: [
                FallbackPanelDigestTagsLimitRule(maxCount: 80, banned: ["rolling", "regional"]),
                FallbackPanelDigestDosageMgRangeRule(min: 4.9, max: 950.0),
                FallbackPanelDigestRequiredCategoryRule(message: "fallback panel digest needs an entry"),
                FallbackPanelDigestRateRangeRule(min: 5.2, max: 187.0),
                FallbackPanelDigestRequiredLocaleRule(message: "fallback panel digest needs this field"),
                FallbackPanelDigestRequiredTitleRule(message: "fallback panel digest needs a value"),
            ]
        )
    }
}
