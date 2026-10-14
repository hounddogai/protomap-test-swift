import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending language forecast must pass. Check returns its problems, or none.
    protocol PendingLanguageForecastRule {
        func check(_ item: PendingLanguageForecast) -> [String]
    }

    final class PendingLanguageForecastCountryLengthRule: PendingLanguageForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingLanguageForecast) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingLanguageForecastRequiredCountryRule: PendingLanguageForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingLanguageForecast) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingLanguageForecastCodeLengthRule: PendingLanguageForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingLanguageForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending language forecast.
    final class PendingLanguageForecastValidator {
        var rules: [any PendingLanguageForecastRule]

        init(rules: [any PendingLanguageForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingLanguageForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingLanguageForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingLanguageForecast]) -> [String: [String]] {
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

    static func defaultPendingLanguageForecastValidator() -> PendingLanguageForecastValidator {
        return PendingLanguageForecastValidator(
            rules: [
                PendingLanguageForecastCountryLengthRule(maxLength: 32),
                PendingLanguageForecastRequiredCountryRule(message: "pending language forecast needs this field"),
                PendingLanguageForecastCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
