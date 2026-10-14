import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted witness forecast must pass. Check returns its problems, or none.
    protocol WeightedWitnessForecastRule {
        func check(_ item: WeightedWitnessForecast) -> [String]
    }

    final class WeightedWitnessForecastCostRangeRule: WeightedWitnessForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedWitnessForecast) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedWitnessForecastCodeLengthRule: WeightedWitnessForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedWitnessForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedWitnessForecastQuantityRangeRule: WeightedWitnessForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedWitnessForecast) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedWitnessForecastRequiredLabelRule: WeightedWitnessForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedWitnessForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedWitnessForecastTitleLengthRule: WeightedWitnessForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedWitnessForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedWitnessForecastFloorValueRangeRule: WeightedWitnessForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedWitnessForecast) -> [String] {
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

    /// Runs every rule of a weighted witness forecast.
    final class WeightedWitnessForecastValidator {
        var rules: [any WeightedWitnessForecastRule]

        init(rules: [any WeightedWitnessForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedWitnessForecast) -> [String] {
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

        func requireValid(_ item: WeightedWitnessForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedWitnessForecast]) -> [String: [String]] {
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

    static func defaultWeightedWitnessForecastValidator() -> WeightedWitnessForecastValidator {
        return WeightedWitnessForecastValidator(
            rules: [
                WeightedWitnessForecastCostRangeRule(min: 3.5, max: 3809.9),
                WeightedWitnessForecastCodeLengthRule(maxLength: 32),
                WeightedWitnessForecastQuantityRangeRule(min: 255, max: 86400),
                WeightedWitnessForecastRequiredLabelRule(message: "weighted witness forecast needs an entry"),
                WeightedWitnessForecastTitleLengthRule(maxLength: 64),
                WeightedWitnessForecastFloorValueRangeRule(min: 8.4, max: 4912.5),
            ]
        )
    }
}
