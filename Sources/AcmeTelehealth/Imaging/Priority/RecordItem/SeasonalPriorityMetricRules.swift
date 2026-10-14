import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal priority metric must pass. Check returns its problems, or none.
    protocol SeasonalPriorityMetricRule {
        func check(_ item: SeasonalPriorityMetric) -> [String]
    }

    final class SeasonalPriorityMetricRateRangeRule: SeasonalPriorityMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalPriorityMetric) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalPriorityMetricRequiredLabelRule: SeasonalPriorityMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalPriorityMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalPriorityMetricBedLengthRule: SeasonalPriorityMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPriorityMetric) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal priority metric.
    final class SeasonalPriorityMetricValidator {
        var rules: [any SeasonalPriorityMetricRule]

        init(rules: [any SeasonalPriorityMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalPriorityMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalPriorityMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalPriorityMetric]) -> [String: [String]] {
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

    static func defaultSeasonalPriorityMetricValidator() -> SeasonalPriorityMetricValidator {
        return SeasonalPriorityMetricValidator(
            rules: [
                SeasonalPriorityMetricRateRangeRule(min: 6.8, max: 1148.6),
                SeasonalPriorityMetricRequiredLabelRule(message: "seasonal priority metric needs this field"),
                SeasonalPriorityMetricBedLengthRule(maxLength: 3600),
            ]
        )
    }
}
