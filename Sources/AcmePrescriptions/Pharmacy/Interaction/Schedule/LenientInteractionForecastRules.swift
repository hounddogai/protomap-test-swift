import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient interaction forecast must pass. Check returns its problems, or none.
    protocol LenientInteractionForecastRule {
        func check(_ item: LenientInteractionForecast) -> [String]
    }

    final class LenientInteractionForecastRequiredRegionRule: LenientInteractionForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInteractionForecast) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInteractionForecastAttemptsRangeRule: LenientInteractionForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientInteractionForecast) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientInteractionForecastLabelLengthRule: LenientInteractionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInteractionForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientInteractionForecastRequiredDescriptionRule: LenientInteractionForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInteractionForecast) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInteractionForecastCodeLengthRule: LenientInteractionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInteractionForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient interaction forecast.
    final class LenientInteractionForecastValidator {
        var rules: [any LenientInteractionForecastRule]

        init(rules: [any LenientInteractionForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientInteractionForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientInteractionForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientInteractionForecast]) -> [String: [String]] {
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

    static func defaultLenientInteractionForecastValidator() -> LenientInteractionForecastValidator {
        return LenientInteractionForecastValidator(
            rules: [
                LenientInteractionForecastRequiredRegionRule(message: "lenient interaction forecast needs this field"),
                LenientInteractionForecastAttemptsRangeRule(min: 64, max: 3600),
                LenientInteractionForecastLabelLengthRule(maxLength: 64),
                LenientInteractionForecastRequiredDescriptionRule(
                    message: "lenient interaction forecast needs a value"
                ),
                LenientInteractionForecastCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
