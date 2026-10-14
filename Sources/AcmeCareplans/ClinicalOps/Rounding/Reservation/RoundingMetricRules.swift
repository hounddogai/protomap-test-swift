import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding metric must pass. Check returns its problems, or none.
    protocol RoundingMetricRule {
        func check(_ item: RoundingMetric) -> [String]
    }

    final class RoundingMetricVersionRangeRule: RoundingMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingMetric) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingMetricCodeLengthRule: RoundingMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingMetricRetriesRangeRule: RoundingMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingMetric) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding metric.
    final class RoundingMetricValidator {
        var rules: [any RoundingMetricRule]

        init(rules: [any RoundingMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingMetric]) -> [String: [String]] {
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

    static func defaultRoundingMetricValidator() -> RoundingMetricValidator {
        return RoundingMetricValidator(
            rules: [
                RoundingMetricVersionRangeRule(min: 64, max: 120),
                RoundingMetricCodeLengthRule(maxLength: 32),
                RoundingMetricRetriesRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
