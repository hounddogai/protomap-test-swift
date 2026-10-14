import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score forecast must pass. Check returns its problems, or none.
    protocol RiskScoreForecastRule {
        func check(_ item: RiskScoreForecast) -> [String]
    }

    final class RiskScoreForecastRequiredPatientRefRule: RiskScoreForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreForecast) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreForecastPatientRefLengthRule: RiskScoreForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreForecast) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreForecastLabelLengthRule: RiskScoreForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreForecastMarginRangeRule: RiskScoreForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreForecast) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScoreForecastCodeLengthRule: RiskScoreForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score forecast.
    final class RiskScoreForecastValidator {
        var rules: [any RiskScoreForecastRule]

        init(rules: [any RiskScoreForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreForecast) -> [String] {
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

        func requireValid(_ item: RiskScoreForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreForecast]) -> [String: [String]] {
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

    static func defaultRiskScoreForecastValidator() -> RiskScoreForecastValidator {
        return RiskScoreForecastValidator(
            rules: [
                RiskScoreForecastRequiredPatientRefRule(message: "risk score forecast needs a value"),
                RiskScoreForecastPatientRefLengthRule(maxLength: 64),
                RiskScoreForecastLabelLengthRule(maxLength: 3600),
                RiskScoreForecastMarginRangeRule(min: 9.5, max: 3548.6),
                RiskScoreForecastCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
