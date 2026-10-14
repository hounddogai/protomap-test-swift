import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language forecast must pass. Check returns its problems, or none.
    protocol LanguageForecastRule {
        func check(_ item: LanguageForecast) -> [String]
    }

    final class LanguageForecastAllowedNameRule: LanguageForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class LanguageForecastCodeLengthRule: LanguageForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageForecastDescriptionLengthRule: LanguageForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageForecast) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageForecastEndsAtRangeRule: LanguageForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageForecast) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a language forecast.
    final class LanguageForecastValidator {
        var rules: [any LanguageForecastRule]

        init(rules: [any LanguageForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageForecast]) -> [String: [String]] {
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

    static func defaultLanguageForecastValidator() -> LanguageForecastValidator {
        return LanguageForecastValidator(
            rules: [
                LanguageForecastAllowedNameRule(allowed: ["batched"]),
                LanguageForecastCodeLengthRule(maxLength: 32),
                LanguageForecastDescriptionLengthRule(maxLength: 3600),
                LanguageForecastEndsAtRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
