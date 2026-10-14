import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global alert forecast must pass. Check returns its problems, or none.
    protocol GlobalAlertForecastRule {
        func check(_ item: GlobalAlertForecast) -> [String]
    }

    final class GlobalAlertForecastRequiredSpecialtyRule: GlobalAlertForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAlertForecast) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAlertForecastExternalRefLengthRule: GlobalAlertForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAlertForecast) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAlertForecastQuantityRangeRule: GlobalAlertForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAlertForecast) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalAlertForecastRequiredExternalRefRule: GlobalAlertForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAlertForecast) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAlertForecastRequiredCodeRule: GlobalAlertForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAlertForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAlertForecastCodeLengthRule: GlobalAlertForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAlertForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global alert forecast.
    final class GlobalAlertForecastValidator {
        var rules: [any GlobalAlertForecastRule]

        init(rules: [any GlobalAlertForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAlertForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAlertForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAlertForecast]) -> [String: [String]] {
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

    static func defaultGlobalAlertForecastValidator() -> GlobalAlertForecastValidator {
        return GlobalAlertForecastValidator(
            rules: [
                GlobalAlertForecastRequiredSpecialtyRule(message: "global alert forecast needs an entry"),
                GlobalAlertForecastExternalRefLengthRule(maxLength: 1000),
                GlobalAlertForecastQuantityRangeRule(min: 64, max: 64),
                GlobalAlertForecastRequiredExternalRefRule(message: "global alert forecast needs a value"),
                GlobalAlertForecastRequiredCodeRule(message: "global alert forecast needs an entry"),
                GlobalAlertForecastCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
