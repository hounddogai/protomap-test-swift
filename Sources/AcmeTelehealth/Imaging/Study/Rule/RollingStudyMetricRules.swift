import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling study metric must pass. Check returns its problems, or none.
    protocol RollingStudyMetricRule {
        func check(_ item: RollingStudyMetric) -> [String]
    }

    final class RollingStudyMetricCreatedAtRangeRule: RollingStudyMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStudyMetric) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingStudyMetricUnitLengthRule: RollingStudyMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStudyMetric) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingStudyMetricMaximumRangeRule: RollingStudyMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStudyMetric) -> [String] {
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

    /// Runs every rule of a rolling study metric.
    final class RollingStudyMetricValidator {
        var rules: [any RollingStudyMetricRule]

        init(rules: [any RollingStudyMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingStudyMetric) -> [String] {
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

        func requireValid(_ item: RollingStudyMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingStudyMetric]) -> [String: [String]] {
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

    static func defaultRollingStudyMetricValidator() -> RollingStudyMetricValidator {
        return RollingStudyMetricValidator(
            rules: [
                RollingStudyMetricCreatedAtRangeRule(min: 80, max: 80),
                RollingStudyMetricUnitLengthRule(maxLength: 1000),
                RollingStudyMetricMaximumRangeRule(min: 9.3, max: 3635.1),
            ]
        )
    }
}
