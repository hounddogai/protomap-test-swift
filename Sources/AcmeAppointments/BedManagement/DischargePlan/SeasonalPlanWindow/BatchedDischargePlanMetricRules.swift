import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched discharge plan metric must pass. Check returns its problems, or none.
    protocol BatchedDischargePlanMetricRule {
        func check(_ item: BatchedDischargePlanMetric) -> [String]
    }

    final class BatchedDischargePlanMetricAttemptsRangeRule: BatchedDischargePlanMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDischargePlanMetric) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedDischargePlanMetricVersionRangeRule: BatchedDischargePlanMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDischargePlanMetric) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedDischargePlanMetricLabelLengthRule: BatchedDischargePlanMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDischargePlanMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched discharge plan metric.
    final class BatchedDischargePlanMetricValidator {
        var rules: [any BatchedDischargePlanMetricRule]

        init(rules: [any BatchedDischargePlanMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDischargePlanMetric) -> [String] {
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

        func requireValid(_ item: BatchedDischargePlanMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDischargePlanMetric]) -> [String: [String]] {
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

    static func defaultBatchedDischargePlanMetricValidator() -> BatchedDischargePlanMetricValidator {
        return BatchedDischargePlanMetricValidator(
            rules: [
                BatchedDischargePlanMetricAttemptsRangeRule(min: 80, max: 1000),
                BatchedDischargePlanMetricVersionRangeRule(min: 80, max: 120),
                BatchedDischargePlanMetricLabelLengthRule(maxLength: 1000),
            ]
        )
    }
}
