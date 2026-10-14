import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual network forecast must pass. Check returns its problems, or none.
    protocol ManualNetworkForecastRule {
        func check(_ item: ManualNetworkForecast) -> [String]
    }

    final class ManualNetworkForecastAllowedCodeRule: ManualNetworkForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualNetworkForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ManualNetworkForecastNameLengthRule: ManualNetworkForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkForecastDurationMinutesRangeRule: ManualNetworkForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkForecast) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual network forecast.
    final class ManualNetworkForecastValidator {
        var rules: [any ManualNetworkForecastRule]

        init(rules: [any ManualNetworkForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualNetworkForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualNetworkForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualNetworkForecast]) -> [String: [String]] {
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

    static func defaultManualNetworkForecastValidator() -> ManualNetworkForecastValidator {
        return ManualNetworkForecastValidator(
            rules: [
                ManualNetworkForecastAllowedCodeRule(allowed: ["scheduled"]),
                ManualNetworkForecastNameLengthRule(maxLength: 1000),
                ManualNetworkForecastDurationMinutesRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
