import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap forecast must pass. Check returns its problems, or none.
    protocol CareGapForecastRule {
        func check(_ item: CareGapForecast) -> [String]
    }

    final class CareGapForecastRequiredSummaryRule: CareGapForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapForecast) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapForecastFloorValueRangeRule: CareGapForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapForecast) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapForecastRequiredCodeRule: CareGapForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapForecastSummaryLengthRule: CareGapForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapForecast) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapForecastAllowedCodeRule: CareGapForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class CareGapForecastWindowDaysRangeRule: CareGapForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapForecast) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care gap forecast.
    final class CareGapForecastValidator {
        var rules: [any CareGapForecastRule]

        init(rules: [any CareGapForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapForecast]) -> [String: [String]] {
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

    static func defaultCareGapForecastValidator() -> CareGapForecastValidator {
        return CareGapForecastValidator(
            rules: [
                CareGapForecastRequiredSummaryRule(message: "care gap forecast needs an entry"),
                CareGapForecastFloorValueRangeRule(min: 6.4, max: 4443.2),
                CareGapForecastRequiredCodeRule(message: "care gap forecast needs this field"),
                CareGapForecastSummaryLengthRule(maxLength: 64),
                CareGapForecastAllowedCodeRule(allowed: []),
                CareGapForecastWindowDaysRangeRule(min: 80, max: 120),
            ]
        )
    }
}
