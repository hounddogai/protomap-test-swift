import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal study metric must pass. Check returns its problems, or none.
    protocol SeasonalStudyMetricRule {
        func check(_ item: SeasonalStudyMetric) -> [String]
    }

    final class SeasonalStudyMetricCodePrefixRule: SeasonalStudyMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalStudyMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalStudyMetricRequiredLabelRule: SeasonalStudyMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStudyMetric) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalStudyMetricDurationMinutesRangeRule: SeasonalStudyMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalStudyMetric) -> [String] {
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

    final class SeasonalStudyMetricAllowedTitleRule: SeasonalStudyMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalStudyMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class SeasonalStudyMetricRateRangeRule: SeasonalStudyMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalStudyMetric) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalStudyMetricRequiredCodeRule: SeasonalStudyMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStudyMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal study metric.
    final class SeasonalStudyMetricValidator {
        var rules: [any SeasonalStudyMetricRule]

        init(rules: [any SeasonalStudyMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalStudyMetric) -> [String] {
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

        func requireValid(_ item: SeasonalStudyMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalStudyMetric]) -> [String: [String]] {
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

    static func defaultSeasonalStudyMetricValidator() -> SeasonalStudyMetricValidator {
        return SeasonalStudyMetricValidator(
            rules: [
                SeasonalStudyMetricCodePrefixRule(prefix: "OPS"),
                SeasonalStudyMetricRequiredLabelRule(message: "seasonal study metric needs a value"),
                SeasonalStudyMetricDurationMinutesRangeRule(min: 32, max: 86400),
                SeasonalStudyMetricAllowedTitleRule(allowed: ["tiered"]),
                SeasonalStudyMetricRateRangeRule(min: 6.3, max: 3555.5),
                SeasonalStudyMetricRequiredCodeRule(message: "seasonal study metric needs an entry"),
            ]
        )
    }
}
