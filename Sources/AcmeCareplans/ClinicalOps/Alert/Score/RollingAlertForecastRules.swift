import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling alert forecast must pass. Check returns its problems, or none.
    protocol RollingAlertForecastRule {
        func check(_ item: RollingAlertForecast) -> [String]
    }

    final class RollingAlertForecastRequiredCurrencyRule: RollingAlertForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertForecast) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAlertForecastCurrencyLengthRule: RollingAlertForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAlertForecast) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAlertForecastRequiredReviewerRule: RollingAlertForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertForecast) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAlertForecastExpiresAtRangeRule: RollingAlertForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingAlertForecast) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling alert forecast.
    final class RollingAlertForecastValidator {
        var rules: [any RollingAlertForecastRule]

        init(rules: [any RollingAlertForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAlertForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAlertForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAlertForecast]) -> [String: [String]] {
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

    static func defaultRollingAlertForecastValidator() -> RollingAlertForecastValidator {
        return RollingAlertForecastValidator(
            rules: [
                RollingAlertForecastRequiredCurrencyRule(message: "rolling alert forecast needs an entry"),
                RollingAlertForecastCurrencyLengthRule(maxLength: 120),
                RollingAlertForecastRequiredReviewerRule(message: "rolling alert forecast needs a value"),
                RollingAlertForecastExpiresAtRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
