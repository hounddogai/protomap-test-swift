import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted dispense metric must pass. Check returns its problems, or none.
    protocol WeightedDispenseMetricRule {
        func check(_ item: WeightedDispenseMetric) -> [String]
    }

    final class WeightedDispenseMetricLimitRangeRule: WeightedDispenseMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedDispenseMetric) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedDispenseMetricCodeLengthRule: WeightedDispenseMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDispenseMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDispenseMetricAllowedCodeRule: WeightedDispenseMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedDispenseMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class WeightedDispenseMetricThresholdRangeRule: WeightedDispenseMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedDispenseMetric) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted dispense metric.
    final class WeightedDispenseMetricValidator {
        var rules: [any WeightedDispenseMetricRule]

        init(rules: [any WeightedDispenseMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedDispenseMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedDispenseMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedDispenseMetric]) -> [String: [String]] {
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

    static func defaultWeightedDispenseMetricValidator() -> WeightedDispenseMetricValidator {
        return WeightedDispenseMetricValidator(
            rules: [
                WeightedDispenseMetricLimitRangeRule(min: 255, max: 3600),
                WeightedDispenseMetricCodeLengthRule(maxLength: 86400),
                WeightedDispenseMetricAllowedCodeRule(allowed: ["batched", "weighted"]),
                WeightedDispenseMetricThresholdRangeRule(min: 6.8, max: 1003.6),
            ]
        )
    }
}
