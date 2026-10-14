import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict language forecast must pass. Check returns its problems, or none.
    protocol StrictLanguageForecastRule {
        func check(_ item: StrictLanguageForecast) -> [String]
    }

    final class StrictLanguageForecastCostRangeRule: StrictLanguageForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictLanguageForecast) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictLanguageForecastRequiredTitleRule: StrictLanguageForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictLanguageForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictLanguageForecastMaximumRangeRule: StrictLanguageForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictLanguageForecast) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictLanguageForecastAllowedCodeRule: StrictLanguageForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictLanguageForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a strict language forecast.
    final class StrictLanguageForecastValidator {
        var rules: [any StrictLanguageForecastRule]

        init(rules: [any StrictLanguageForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictLanguageForecast) -> [String] {
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

        func requireValid(_ item: StrictLanguageForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictLanguageForecast]) -> [String: [String]] {
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

    static func defaultStrictLanguageForecastValidator() -> StrictLanguageForecastValidator {
        return StrictLanguageForecastValidator(
            rules: [
                StrictLanguageForecastCostRangeRule(min: 0.8, max: 4533.8),
                StrictLanguageForecastRequiredTitleRule(message: "strict language forecast needs a value"),
                StrictLanguageForecastMaximumRangeRule(min: 8.6, max: 4033.1),
                StrictLanguageForecastAllowedCodeRule(allowed: []),
            ]
        )
    }
}
