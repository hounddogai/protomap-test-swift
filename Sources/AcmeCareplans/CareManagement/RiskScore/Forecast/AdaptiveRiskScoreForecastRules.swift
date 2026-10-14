import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive risk score forecast must pass. Check returns its problems, or none.
    protocol AdaptiveRiskScoreForecastRule {
        func check(_ item: AdaptiveRiskScoreForecast) -> [String]
    }

    final class AdaptiveRiskScoreForecastNameLengthRule: AdaptiveRiskScoreForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRiskScoreForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreForecastCodeLengthRule: AdaptiveRiskScoreForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRiskScoreForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreForecastPriorityRangeRule: AdaptiveRiskScoreForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRiskScoreForecast) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive risk score forecast.
    final class AdaptiveRiskScoreForecastValidator {
        var rules: [any AdaptiveRiskScoreForecastRule]

        init(rules: [any AdaptiveRiskScoreForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRiskScoreForecast) -> [String] {
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

        func requireValid(_ item: AdaptiveRiskScoreForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRiskScoreForecast]) -> [String: [String]] {
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

    static func defaultAdaptiveRiskScoreForecastValidator() -> AdaptiveRiskScoreForecastValidator {
        return AdaptiveRiskScoreForecastValidator(
            rules: [
                AdaptiveRiskScoreForecastNameLengthRule(maxLength: 120),
                AdaptiveRiskScoreForecastCodeLengthRule(maxLength: 86400),
                AdaptiveRiskScoreForecastPriorityRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
