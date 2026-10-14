import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled discharge plan forecast must pass. Check returns its problems, or none.
    protocol ScheduledDischargePlanForecastRule {
        func check(_ item: ScheduledDischargePlanForecast) -> [String]
    }

    final class ScheduledDischargePlanForecastReviewerLengthRule: ScheduledDischargePlanForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledDischargePlanForecast) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledDischargePlanForecastLabelLengthRule: ScheduledDischargePlanForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledDischargePlanForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledDischargePlanForecastRequiredLabelRule: ScheduledDischargePlanForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDischargePlanForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled discharge plan forecast.
    final class ScheduledDischargePlanForecastValidator {
        var rules: [any ScheduledDischargePlanForecastRule]

        init(rules: [any ScheduledDischargePlanForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledDischargePlanForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledDischargePlanForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledDischargePlanForecast]) -> [String: [String]] {
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

    static func defaultScheduledDischargePlanForecastValidator() -> ScheduledDischargePlanForecastValidator {
        return ScheduledDischargePlanForecastValidator(
            rules: [
                ScheduledDischargePlanForecastReviewerLengthRule(maxLength: 80),
                ScheduledDischargePlanForecastLabelLengthRule(maxLength: 16),
                ScheduledDischargePlanForecastRequiredLabelRule(
                    message: "scheduled discharge plan forecast needs a value"
                ),
            ]
        )
    }
}
