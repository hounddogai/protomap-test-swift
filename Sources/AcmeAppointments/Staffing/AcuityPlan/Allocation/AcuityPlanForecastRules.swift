import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan forecast must pass. Check returns its problems, or none.
    protocol AcuityPlanForecastRule {
        func check(_ item: AcuityPlanForecast) -> [String]
    }

    final class AcuityPlanForecastRatioRangeRule: AcuityPlanForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanForecast) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanForecastPriorityRangeRule: AcuityPlanForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanForecast) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AcuityPlanForecastRequiredSummaryRule: AcuityPlanForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanForecast) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanForecastCodeLengthRule: AcuityPlanForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan forecast.
    final class AcuityPlanForecastValidator {
        var rules: [any AcuityPlanForecastRule]

        init(rules: [any AcuityPlanForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanForecast) -> [String] {
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

        func requireValid(_ item: AcuityPlanForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanForecast]) -> [String: [String]] {
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

    static func defaultAcuityPlanForecastValidator() -> AcuityPlanForecastValidator {
        return AcuityPlanForecastValidator(
            rules: [
                AcuityPlanForecastRatioRangeRule(min: 6.0, max: 1158.9),
                AcuityPlanForecastPriorityRangeRule(min: 80, max: 1000),
                AcuityPlanForecastRequiredSummaryRule(message: "acuity plan forecast needs this field"),
                AcuityPlanForecastCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
