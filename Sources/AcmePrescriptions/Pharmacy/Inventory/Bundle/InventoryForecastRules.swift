import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory forecast must pass. Check returns its problems, or none.
    protocol InventoryForecastRule {
        func check(_ item: InventoryForecast) -> [String]
    }

    final class InventoryForecastRequiredLabelRule: InventoryForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryForecastRequiredNameRule: InventoryForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryForecastScoreRangeRule: InventoryForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryForecast) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryForecastCodeLengthRule: InventoryForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory forecast.
    final class InventoryForecastValidator {
        var rules: [any InventoryForecastRule]

        init(rules: [any InventoryForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryForecast]) -> [String: [String]] {
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

    static func defaultInventoryForecastValidator() -> InventoryForecastValidator {
        return InventoryForecastValidator(
            rules: [
                InventoryForecastRequiredLabelRule(message: "inventory forecast needs a value"),
                InventoryForecastRequiredNameRule(message: "inventory forecast needs an entry"),
                InventoryForecastScoreRangeRule(min: 5.8, max: 3823.1),
                InventoryForecastCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
