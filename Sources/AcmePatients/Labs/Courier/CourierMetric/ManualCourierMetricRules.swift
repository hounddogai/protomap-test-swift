import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual courier metric must pass. Check returns its problems, or none.
    protocol ManualCourierMetricRule {
        func check(_ item: ManualCourierMetric) -> [String]
    }

    final class ManualCourierMetricRetriesRangeRule: ManualCourierMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCourierMetric) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualCourierMetricCodePrefixRule: ManualCourierMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualCourierMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualCourierMetricMaximumRangeRule: ManualCourierMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCourierMetric) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualCourierMetricDurationMinutesRangeRule: ManualCourierMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCourierMetric) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual courier metric.
    final class ManualCourierMetricValidator {
        var rules: [any ManualCourierMetricRule]

        init(rules: [any ManualCourierMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCourierMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCourierMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCourierMetric]) -> [String: [String]] {
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

    static func defaultManualCourierMetricValidator() -> ManualCourierMetricValidator {
        return ManualCourierMetricValidator(
            rules: [
                ManualCourierMetricRetriesRangeRule(min: 16, max: 32),
                ManualCourierMetricCodePrefixRule(prefix: "X"),
                ManualCourierMetricMaximumRangeRule(min: 2.5, max: 3055.3),
                ManualCourierMetricDurationMinutesRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
