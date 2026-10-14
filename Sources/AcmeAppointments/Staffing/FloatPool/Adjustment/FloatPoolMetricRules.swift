import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool metric must pass. Check returns its problems, or none.
    protocol FloatPoolMetricRule {
        func check(_ item: FloatPoolMetric) -> [String]
    }

    final class FloatPoolMetricNameLengthRule: FloatPoolMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolMetricScoreRangeRule: FloatPoolMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolMetric) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FloatPoolMetricWindowDaysRangeRule: FloatPoolMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolMetric) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolMetricRequiredTitleRule: FloatPoolMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolMetricTitleLengthRule: FloatPoolMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool metric.
    final class FloatPoolMetricValidator {
        var rules: [any FloatPoolMetricRule]

        init(rules: [any FloatPoolMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolMetric]) -> [String: [String]] {
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

    static func defaultFloatPoolMetricValidator() -> FloatPoolMetricValidator {
        return FloatPoolMetricValidator(
            rules: [
                FloatPoolMetricNameLengthRule(maxLength: 32),
                FloatPoolMetricScoreRangeRule(min: 6.4, max: 4489.7),
                FloatPoolMetricWindowDaysRangeRule(min: 255, max: 1000),
                FloatPoolMetricRequiredTitleRule(message: "float pool metric needs this field"),
                FloatPoolMetricTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
