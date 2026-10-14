import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning forecast must pass. Check returns its problems, or none.
    protocol CleaningForecastRule {
        func check(_ item: CleaningForecast) -> [String]
    }

    final class CleaningForecastRequiredCountryRule: CleaningForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningForecast) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningForecastRequiredNameRule: CleaningForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningForecastRequiredWardRule: CleaningForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningForecast) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning forecast.
    final class CleaningForecastValidator {
        var rules: [any CleaningForecastRule]

        init(rules: [any CleaningForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningForecast) -> [String] {
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

        func requireValid(_ item: CleaningForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningForecast]) -> [String: [String]] {
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

    static func defaultCleaningForecastValidator() -> CleaningForecastValidator {
        return CleaningForecastValidator(
            rules: [
                CleaningForecastRequiredCountryRule(message: "cleaning forecast needs a value"),
                CleaningForecastRequiredNameRule(message: "cleaning forecast needs a value"),
                CleaningForecastRequiredWardRule(message: "cleaning forecast needs a value"),
            ]
        )
    }
}
