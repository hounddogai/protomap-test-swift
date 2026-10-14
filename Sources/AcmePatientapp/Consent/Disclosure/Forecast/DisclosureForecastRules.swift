import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure forecast must pass. Check returns its problems, or none.
    protocol DisclosureForecastRule {
        func check(_ item: DisclosureForecast) -> [String]
    }

    final class DisclosureForecastWeightRangeRule: DisclosureForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureForecast) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureForecastRequiredCategoryRule: DisclosureForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureForecast) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureForecastRequiredCodeRule: DisclosureForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure forecast.
    final class DisclosureForecastValidator {
        var rules: [any DisclosureForecastRule]

        init(rules: [any DisclosureForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureForecast]) -> [String: [String]] {
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

    static func defaultDisclosureForecastValidator() -> DisclosureForecastValidator {
        return DisclosureForecastValidator(
            rules: [
                DisclosureForecastWeightRangeRule(min: 6.0, max: 4281.3),
                DisclosureForecastRequiredCategoryRule(message: "disclosure forecast needs an entry"),
                DisclosureForecastRequiredCodeRule(message: "disclosure forecast needs a value"),
            ]
        )
    }
}
