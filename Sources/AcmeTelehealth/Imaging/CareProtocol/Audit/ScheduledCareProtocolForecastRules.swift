import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled care protocol forecast must pass. Check returns its problems, or none.
    protocol ScheduledCareProtocolForecastRule {
        func check(_ item: ScheduledCareProtocolForecast) -> [String]
    }

    final class ScheduledCareProtocolForecastAllowedCodeRule: ScheduledCareProtocolForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCareProtocolForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolForecastNameLengthRule: ScheduledCareProtocolForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolForecastRatioRangeRule: ScheduledCareProtocolForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCareProtocolForecast) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolForecastRequiredCodeRule: ScheduledCareProtocolForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care protocol forecast.
    final class ScheduledCareProtocolForecastValidator {
        var rules: [any ScheduledCareProtocolForecastRule]

        init(rules: [any ScheduledCareProtocolForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareProtocolForecast) -> [String] {
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

        func requireValid(_ item: ScheduledCareProtocolForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareProtocolForecast]) -> [String: [String]] {
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

    static func defaultScheduledCareProtocolForecastValidator() -> ScheduledCareProtocolForecastValidator {
        return ScheduledCareProtocolForecastValidator(
            rules: [
                ScheduledCareProtocolForecastAllowedCodeRule(allowed: []),
                ScheduledCareProtocolForecastNameLengthRule(maxLength: 64),
                ScheduledCareProtocolForecastRatioRangeRule(min: 4.6, max: 1940.6),
                ScheduledCareProtocolForecastRequiredCodeRule(
                    message: "scheduled care protocol forecast needs this field"
                ),
            ]
        )
    }
}
