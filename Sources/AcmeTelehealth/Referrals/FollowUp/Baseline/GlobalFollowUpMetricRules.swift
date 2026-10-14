import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global follow up metric must pass. Check returns its problems, or none.
    protocol GlobalFollowUpMetricRule {
        func check(_ item: GlobalFollowUpMetric) -> [String]
    }

    final class GlobalFollowUpMetricCapacityRangeRule: GlobalFollowUpMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFollowUpMetric) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalFollowUpMetricAllowedCodeRule: GlobalFollowUpMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalFollowUpMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class GlobalFollowUpMetricRatioRangeRule: GlobalFollowUpMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFollowUpMetric) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalFollowUpMetricNameLengthRule: GlobalFollowUpMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFollowUpMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalFollowUpMetricSummaryLengthRule: GlobalFollowUpMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFollowUpMetric) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global follow up metric.
    final class GlobalFollowUpMetricValidator {
        var rules: [any GlobalFollowUpMetricRule]

        init(rules: [any GlobalFollowUpMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalFollowUpMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalFollowUpMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalFollowUpMetric]) -> [String: [String]] {
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

    static func defaultGlobalFollowUpMetricValidator() -> GlobalFollowUpMetricValidator {
        return GlobalFollowUpMetricValidator(
            rules: [
                GlobalFollowUpMetricCapacityRangeRule(min: 16, max: 3600),
                GlobalFollowUpMetricAllowedCodeRule(allowed: []),
                GlobalFollowUpMetricRatioRangeRule(min: 3.8, max: 3390.8),
                GlobalFollowUpMetricNameLengthRule(maxLength: 3600),
                GlobalFollowUpMetricSummaryLengthRule(maxLength: 120),
            ]
        )
    }
}
