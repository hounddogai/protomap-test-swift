import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal accession forecast must pass. Check returns its problems, or none.
    protocol SeasonalAccessionForecastRule {
        func check(_ item: SeasonalAccessionForecast) -> [String]
    }

    final class SeasonalAccessionForecastDescriptionLengthRule: SeasonalAccessionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAccessionForecast) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAccessionForecastCopayRangeRule: SeasonalAccessionForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAccessionForecast) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalAccessionForecastLabelLengthRule: SeasonalAccessionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAccessionForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal accession forecast.
    final class SeasonalAccessionForecastValidator {
        var rules: [any SeasonalAccessionForecastRule]

        init(rules: [any SeasonalAccessionForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAccessionForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalAccessionForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAccessionForecast]) -> [String: [String]] {
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

    static func defaultSeasonalAccessionForecastValidator() -> SeasonalAccessionForecastValidator {
        return SeasonalAccessionForecastValidator(
            rules: [
                SeasonalAccessionForecastDescriptionLengthRule(maxLength: 32),
                SeasonalAccessionForecastCopayRangeRule(min: 7.3, max: 1902.5),
                SeasonalAccessionForecastLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
