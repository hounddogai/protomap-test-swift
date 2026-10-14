import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional proxy forecast must pass. Check returns its problems, or none.
    protocol RegionalProxyForecastRule {
        func check(_ item: RegionalProxyForecast) -> [String]
    }

    final class RegionalProxyForecastTitleLengthRule: RegionalProxyForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalProxyForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalProxyForecastAllowedTitleRule: RegionalProxyForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalProxyForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    final class RegionalProxyForecastLimitRangeRule: RegionalProxyForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalProxyForecast) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalProxyForecastRequiredCodeRule: RegionalProxyForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalProxyForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional proxy forecast.
    final class RegionalProxyForecastValidator {
        var rules: [any RegionalProxyForecastRule]

        init(rules: [any RegionalProxyForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalProxyForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalProxyForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalProxyForecast]) -> [String: [String]] {
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

    static func defaultRegionalProxyForecastValidator() -> RegionalProxyForecastValidator {
        return RegionalProxyForecastValidator(
            rules: [
                RegionalProxyForecastTitleLengthRule(maxLength: 80),
                RegionalProxyForecastAllowedTitleRule(allowed: ["seasonal"]),
                RegionalProxyForecastLimitRangeRule(min: 32, max: 1000),
                RegionalProxyForecastRequiredCodeRule(message: "regional proxy forecast needs this field"),
            ]
        )
    }
}
