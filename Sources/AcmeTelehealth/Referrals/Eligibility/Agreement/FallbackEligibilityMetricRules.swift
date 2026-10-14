import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback eligibility metric must pass. Check returns its problems, or none.
    protocol FallbackEligibilityMetricRule {
        func check(_ item: FallbackEligibilityMetric) -> [String]
    }

    final class FallbackEligibilityMetricTagsLimitRule: FallbackEligibilityMetricRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FallbackEligibilityMetric) -> [String] {
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

    final class FallbackEligibilityMetricRequiredWardRule: FallbackEligibilityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityMetric) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityMetricRequiredNameRule: FallbackEligibilityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityMetricRequiredCurrencyRule: FallbackEligibilityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityMetric) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityMetricCodeLengthRule: FallbackEligibilityMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackEligibilityMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback eligibility metric.
    final class FallbackEligibilityMetricValidator {
        var rules: [any FallbackEligibilityMetricRule]

        init(rules: [any FallbackEligibilityMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackEligibilityMetric) -> [String] {
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

        func requireValid(_ item: FallbackEligibilityMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackEligibilityMetric]) -> [String: [String]] {
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

    static func defaultFallbackEligibilityMetricValidator() -> FallbackEligibilityMetricValidator {
        return FallbackEligibilityMetricValidator(
            rules: [
                FallbackEligibilityMetricTagsLimitRule(maxCount: 32, banned: ["regional", "tiered", "global"]),
                FallbackEligibilityMetricRequiredWardRule(message: "fallback eligibility metric needs this field"),
                FallbackEligibilityMetricRequiredNameRule(message: "fallback eligibility metric needs this field"),
                FallbackEligibilityMetricRequiredCurrencyRule(message: "fallback eligibility metric needs a value"),
                FallbackEligibilityMetricCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
