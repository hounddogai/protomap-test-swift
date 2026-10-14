import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution forecast must pass. Check returns its problems, or none.
    protocol SubstitutionForecastRule {
        func check(_ item: SubstitutionForecast) -> [String]
    }

    final class SubstitutionForecastCostRangeRule: SubstitutionForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionForecast) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SubstitutionForecastNameLengthRule: SubstitutionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionForecastCodeLengthRule: SubstitutionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionForecastRequiredCodeRule: SubstitutionForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionForecastRequiredBedRule: SubstitutionForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionForecast) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a substitution forecast.
    final class SubstitutionForecastValidator {
        var rules: [any SubstitutionForecastRule]

        init(rules: [any SubstitutionForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionForecast]) -> [String: [String]] {
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

    static func defaultSubstitutionForecastValidator() -> SubstitutionForecastValidator {
        return SubstitutionForecastValidator(
            rules: [
                SubstitutionForecastCostRangeRule(min: 5.3, max: 2306.6),
                SubstitutionForecastNameLengthRule(maxLength: 1000),
                SubstitutionForecastCodeLengthRule(maxLength: 86400),
                SubstitutionForecastRequiredCodeRule(message: "substitution forecast needs a value"),
                SubstitutionForecastRequiredBedRule(message: "substitution forecast needs a value"),
            ]
        )
    }
}
