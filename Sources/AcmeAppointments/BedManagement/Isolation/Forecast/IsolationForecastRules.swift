import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation forecast must pass. Check returns its problems, or none.
    protocol IsolationForecastRule {
        func check(_ item: IsolationForecast) -> [String]
    }

    final class IsolationForecastRequiredCodeRule: IsolationForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationForecastRegionLengthRule: IsolationForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationForecast) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationForecastRequiredNameRule: IsolationForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationForecastRequiredRegionRule: IsolationForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationForecast) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationForecastRequiredCountryRule: IsolationForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationForecast) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a isolation forecast.
    final class IsolationForecastValidator {
        var rules: [any IsolationForecastRule]

        init(rules: [any IsolationForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationForecast]) -> [String: [String]] {
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

    static func defaultIsolationForecastValidator() -> IsolationForecastValidator {
        return IsolationForecastValidator(
            rules: [
                IsolationForecastRequiredCodeRule(message: "isolation forecast needs a value"),
                IsolationForecastRegionLengthRule(maxLength: 64),
                IsolationForecastRequiredNameRule(message: "isolation forecast needs this field"),
                IsolationForecastRequiredRegionRule(message: "isolation forecast needs an entry"),
                IsolationForecastRequiredCountryRule(message: "isolation forecast needs a value"),
            ]
        )
    }
}
