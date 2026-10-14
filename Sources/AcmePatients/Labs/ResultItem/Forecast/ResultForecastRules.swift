import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result forecast must pass. Check returns its problems, or none.
    protocol ResultForecastRule {
        func check(_ item: ResultForecast) -> [String]
    }

    final class ResultForecastRequiredLocaleRule: ResultForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultForecast) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultForecastFloorValueRangeRule: ResultForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultForecast) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultForecastRequiredCodeRule: ResultForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultForecastCodePrefixRule: ResultForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ResultForecastWeightRangeRule: ResultForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultForecast) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultForecastLocaleLengthRule: ResultForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultForecast) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result forecast.
    final class ResultForecastValidator {
        var rules: [any ResultForecastRule]

        init(rules: [any ResultForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultForecast) -> [String] {
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

        func requireValid(_ item: ResultForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultForecast]) -> [String: [String]] {
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

    static func defaultResultForecastValidator() -> ResultForecastValidator {
        return ResultForecastValidator(
            rules: [
                ResultForecastRequiredLocaleRule(message: "result forecast needs a value"),
                ResultForecastFloorValueRangeRule(min: 10.0, max: 2789.9),
                ResultForecastRequiredCodeRule(message: "result forecast needs a value"),
                ResultForecastCodePrefixRule(prefix: "X"),
                ResultForecastWeightRangeRule(min: 4.7, max: 4202.7),
                ResultForecastLocaleLengthRule(maxLength: 80),
            ]
        )
    }
}
