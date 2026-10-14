import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered goal forecast must pass. Check returns its problems, or none.
    protocol TieredGoalForecastRule {
        func check(_ item: TieredGoalForecast) -> [String]
    }

    final class TieredGoalForecastRequiredCodeRule: TieredGoalForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredGoalForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredGoalForecastRequiredFacilityRule: TieredGoalForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredGoalForecast) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredGoalForecastVersionRangeRule: TieredGoalForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredGoalForecast) -> [String] {
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

    final class TieredGoalForecastFacilityLengthRule: TieredGoalForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredGoalForecast) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered goal forecast.
    final class TieredGoalForecastValidator {
        var rules: [any TieredGoalForecastRule]

        init(rules: [any TieredGoalForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredGoalForecast) -> [String] {
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

        func requireValid(_ item: TieredGoalForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredGoalForecast]) -> [String: [String]] {
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

    static func defaultTieredGoalForecastValidator() -> TieredGoalForecastValidator {
        return TieredGoalForecastValidator(
            rules: [
                TieredGoalForecastRequiredCodeRule(message: "tiered goal forecast needs a value"),
                TieredGoalForecastRequiredFacilityRule(message: "tiered goal forecast needs a value"),
                TieredGoalForecastVersionRangeRule(min: 64, max: 1000),
                TieredGoalForecastFacilityLengthRule(maxLength: 1000),
            ]
        )
    }
}
