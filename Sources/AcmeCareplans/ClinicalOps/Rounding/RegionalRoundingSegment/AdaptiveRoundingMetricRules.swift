import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive rounding metric must pass. Check returns its problems, or none.
    protocol AdaptiveRoundingMetricRule {
        func check(_ item: AdaptiveRoundingMetric) -> [String]
    }

    final class AdaptiveRoundingMetricRequiredCodeRule: AdaptiveRoundingMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRoundingMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRoundingMetricRequiredTitleRule: AdaptiveRoundingMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRoundingMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRoundingMetricRequiredNameRule: AdaptiveRoundingMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRoundingMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRoundingMetricRegionLengthRule: AdaptiveRoundingMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRoundingMetric) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRoundingMetricCreatedAtRangeRule: AdaptiveRoundingMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRoundingMetric) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive rounding metric.
    final class AdaptiveRoundingMetricValidator {
        var rules: [any AdaptiveRoundingMetricRule]

        init(rules: [any AdaptiveRoundingMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRoundingMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveRoundingMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRoundingMetric]) -> [String: [String]] {
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

    static func defaultAdaptiveRoundingMetricValidator() -> AdaptiveRoundingMetricValidator {
        return AdaptiveRoundingMetricValidator(
            rules: [
                AdaptiveRoundingMetricRequiredCodeRule(message: "adaptive rounding metric needs a value"),
                AdaptiveRoundingMetricRequiredTitleRule(message: "adaptive rounding metric needs a value"),
                AdaptiveRoundingMetricRequiredNameRule(message: "adaptive rounding metric needs a value"),
                AdaptiveRoundingMetricRegionLengthRule(maxLength: 80),
                AdaptiveRoundingMetricCreatedAtRangeRule(min: 32, max: 64),
            ]
        )
    }
}
