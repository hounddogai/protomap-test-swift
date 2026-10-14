import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a seasonal denial forecast must pass. Check returns its problems, or none.
    protocol SeasonalDenialForecastRule {
        func check(_ item: SeasonalDenialForecast) -> [String]
    }

    final class SeasonalDenialForecastRequiredReviewerRule: SeasonalDenialForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalDenialForecast) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalDenialForecastCodePrefixRule: SeasonalDenialForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalDenialForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalDenialForecastBudgetRangeRule: SeasonalDenialForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalDenialForecast) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalDenialForecastExternalRefLengthRule: SeasonalDenialForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalDenialForecast) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal denial forecast.
    final class SeasonalDenialForecastValidator {
        var rules: [any SeasonalDenialForecastRule]

        init(rules: [any SeasonalDenialForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalDenialForecast) -> [String] {
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

        func requireValid(_ item: SeasonalDenialForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalDenialForecast]) -> [String: [String]] {
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

    static func defaultSeasonalDenialForecastValidator() -> SeasonalDenialForecastValidator {
        return SeasonalDenialForecastValidator(
            rules: [
                SeasonalDenialForecastRequiredReviewerRule(message: "seasonal denial forecast needs this field"),
                SeasonalDenialForecastCodePrefixRule(prefix: "OPS"),
                SeasonalDenialForecastBudgetRangeRule(min: 2.1, max: 3965.0),
                SeasonalDenialForecastExternalRefLengthRule(maxLength: 64),
            ]
        )
    }
}
