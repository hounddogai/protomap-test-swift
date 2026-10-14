import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense forecast must pass. Check returns its problems, or none.
    protocol DispenseForecastRule {
        func check(_ item: DispenseForecast) -> [String]
    }

    final class DispenseForecastReviewerLengthRule: DispenseForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseForecast) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseForecastRequiredFacilityRule: DispenseForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseForecast) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseForecastEndsAtRangeRule: DispenseForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseForecast) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseForecastRequiredNameRule: DispenseForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseForecastRequiredReviewerRule: DispenseForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseForecast) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseForecastRateRangeRule: DispenseForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseForecast) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a dispense forecast.
    final class DispenseForecastValidator {
        var rules: [any DispenseForecastRule]

        init(rules: [any DispenseForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseForecast) -> [String] {
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

        func requireValid(_ item: DispenseForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseForecast]) -> [String: [String]] {
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

    static func defaultDispenseForecastValidator() -> DispenseForecastValidator {
        return DispenseForecastValidator(
            rules: [
                DispenseForecastReviewerLengthRule(maxLength: 86400),
                DispenseForecastRequiredFacilityRule(message: "dispense forecast needs this field"),
                DispenseForecastEndsAtRangeRule(min: 80, max: 86400),
                DispenseForecastRequiredNameRule(message: "dispense forecast needs an entry"),
                DispenseForecastRequiredReviewerRule(message: "dispense forecast needs this field"),
                DispenseForecastRateRangeRule(min: 3.7, max: 2594.7),
            ]
        )
    }
}
