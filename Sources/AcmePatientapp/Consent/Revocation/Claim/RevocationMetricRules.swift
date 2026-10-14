import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation metric must pass. Check returns its problems, or none.
    protocol RevocationMetricRule {
        func check(_ item: RevocationMetric) -> [String]
    }

    final class RevocationMetricTagsLimitRule: RevocationMetricRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RevocationMetric) -> [String] {
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

    final class RevocationMetricDiscountRangeRule: RevocationMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationMetric) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RevocationMetricDurationMinutesRangeRule: RevocationMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationMetric) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation metric.
    final class RevocationMetricValidator {
        var rules: [any RevocationMetricRule]

        init(rules: [any RevocationMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationMetric) -> [String] {
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

        func requireValid(_ item: RevocationMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationMetric]) -> [String: [String]] {
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

    static func defaultRevocationMetricValidator() -> RevocationMetricValidator {
        return RevocationMetricValidator(
            rules: [
                RevocationMetricTagsLimitRule(maxCount: 3600, banned: []),
                RevocationMetricDiscountRangeRule(min: 7.7, max: 1372.9),
                RevocationMetricDurationMinutesRangeRule(min: 16, max: 255),
            ]
        )
    }
}
