import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census forecast must pass. Check returns its problems, or none.
    protocol CensusForecastRule {
        func check(_ item: CensusForecast) -> [String]
    }

    final class CensusForecastNameLengthRule: CensusForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusForecastCodeLengthRule: CensusForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusForecastRequiredCodeRule: CensusForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census forecast.
    final class CensusForecastValidator {
        var rules: [any CensusForecastRule]

        init(rules: [any CensusForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusForecast]) -> [String: [String]] {
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

    static func defaultCensusForecastValidator() -> CensusForecastValidator {
        return CensusForecastValidator(
            rules: [
                CensusForecastNameLengthRule(maxLength: 120),
                CensusForecastCodeLengthRule(maxLength: 16),
                CensusForecastRequiredCodeRule(message: "census forecast needs an entry"),
            ]
        )
    }
}
