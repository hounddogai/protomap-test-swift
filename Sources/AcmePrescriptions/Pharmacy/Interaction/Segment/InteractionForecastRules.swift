import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction forecast must pass. Check returns its problems, or none.
    protocol InteractionForecastRule {
        func check(_ item: InteractionForecast) -> [String]
    }

    final class InteractionForecastRequiredNotesRule: InteractionForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionForecast) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionForecastNotesLengthRule: InteractionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionForecast) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionForecastWindowDaysRangeRule: InteractionForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionForecast) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionForecastCodeLengthRule: InteractionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction forecast.
    final class InteractionForecastValidator {
        var rules: [any InteractionForecastRule]

        init(rules: [any InteractionForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionForecast]) -> [String: [String]] {
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

    static func defaultInteractionForecastValidator() -> InteractionForecastValidator {
        return InteractionForecastValidator(
            rules: [
                InteractionForecastRequiredNotesRule(message: "interaction forecast needs a value"),
                InteractionForecastNotesLengthRule(maxLength: 255),
                InteractionForecastWindowDaysRangeRule(min: 80, max: 86400),
                InteractionForecastCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
