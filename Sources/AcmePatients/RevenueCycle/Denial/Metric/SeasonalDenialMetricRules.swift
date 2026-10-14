import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a seasonal denial metric must pass. Check returns its problems, or none.
    protocol SeasonalDenialMetricRule {
        func check(_ item: SeasonalDenialMetric) -> [String]
    }

    final class SeasonalDenialMetricCostRangeRule: SeasonalDenialMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDenialMetric) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalDenialMetricAllowedTitleRule: SeasonalDenialMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalDenialMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class SeasonalDenialMetricCodePrefixRule: SeasonalDenialMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalDenialMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalDenialMetricRequiredDescriptionRule: SeasonalDenialMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalDenialMetric) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal denial metric.
    final class SeasonalDenialMetricValidator {
        var rules: [any SeasonalDenialMetricRule]

        init(rules: [any SeasonalDenialMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalDenialMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalDenialMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalDenialMetric]) -> [String: [String]] {
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

    static func defaultSeasonalDenialMetricValidator() -> SeasonalDenialMetricValidator {
        return SeasonalDenialMetricValidator(
            rules: [
                SeasonalDenialMetricCostRangeRule(min: 4.1, max: 3203.7),
                SeasonalDenialMetricAllowedTitleRule(allowed: ["rolling", "weighted"]),
                SeasonalDenialMetricCodePrefixRule(prefix: "REF"),
                SeasonalDenialMetricRequiredDescriptionRule(message: "seasonal denial metric needs this field"),
            ]
        )
    }
}
