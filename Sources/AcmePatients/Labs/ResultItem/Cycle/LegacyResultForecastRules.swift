import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy result forecast must pass. Check returns its problems, or none.
    protocol LegacyResultForecastRule {
        func check(_ item: LegacyResultForecast) -> [String]
    }

    final class LegacyResultForecastRequiredPayerRule: LegacyResultForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyResultForecast) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyResultForecastCodePrefixRule: LegacyResultForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyResultForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyResultForecastCeilingRangeRule: LegacyResultForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyResultForecast) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyResultForecastRateRangeRule: LegacyResultForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyResultForecast) -> [String] {
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

    /// Runs every rule of a legacy result forecast.
    final class LegacyResultForecastValidator {
        var rules: [any LegacyResultForecastRule]

        init(rules: [any LegacyResultForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyResultForecast) -> [String] {
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

        func requireValid(_ item: LegacyResultForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyResultForecast]) -> [String: [String]] {
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

    static func defaultLegacyResultForecastValidator() -> LegacyResultForecastValidator {
        return LegacyResultForecastValidator(
            rules: [
                LegacyResultForecastRequiredPayerRule(message: "legacy result forecast needs an entry"),
                LegacyResultForecastCodePrefixRule(prefix: "OPS"),
                LegacyResultForecastCeilingRangeRule(min: 0.9, max: 475.1),
                LegacyResultForecastRateRangeRule(min: 8.0, max: 4828.4),
            ]
        )
    }
}
