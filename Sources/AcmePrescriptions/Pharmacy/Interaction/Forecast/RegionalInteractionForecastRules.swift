import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional interaction forecast must pass. Check returns its problems, or none.
    protocol RegionalInteractionForecastRule {
        func check(_ item: RegionalInteractionForecast) -> [String]
    }

    final class RegionalInteractionForecastCodePrefixRule: RegionalInteractionForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalInteractionForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalInteractionForecastDurationMinutesRangeRule: RegionalInteractionForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalInteractionForecast) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalInteractionForecastRequiredNameRule: RegionalInteractionForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalInteractionForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalInteractionForecastNameLengthRule: RegionalInteractionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalInteractionForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalInteractionForecastAllowedNameRule: RegionalInteractionForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalInteractionForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class RegionalInteractionForecastCodeLengthRule: RegionalInteractionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalInteractionForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional interaction forecast.
    final class RegionalInteractionForecastValidator {
        var rules: [any RegionalInteractionForecastRule]

        init(rules: [any RegionalInteractionForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalInteractionForecast) -> [String] {
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

        func requireValid(_ item: RegionalInteractionForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalInteractionForecast]) -> [String: [String]] {
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

    static func defaultRegionalInteractionForecastValidator() -> RegionalInteractionForecastValidator {
        return RegionalInteractionForecastValidator(
            rules: [
                RegionalInteractionForecastCodePrefixRule(prefix: "X"),
                RegionalInteractionForecastDurationMinutesRangeRule(min: 120, max: 86400),
                RegionalInteractionForecastRequiredNameRule(message: "regional interaction forecast needs an entry"),
                RegionalInteractionForecastNameLengthRule(maxLength: 255),
                RegionalInteractionForecastAllowedNameRule(allowed: []),
                RegionalInteractionForecastCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
