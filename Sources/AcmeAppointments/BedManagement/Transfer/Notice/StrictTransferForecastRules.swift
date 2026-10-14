import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict transfer forecast must pass. Check returns its problems, or none.
    protocol StrictTransferForecastRule {
        func check(_ item: StrictTransferForecast) -> [String]
    }

    final class StrictTransferForecastRequiredCodeRule: StrictTransferForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictTransferForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictTransferForecastCurrencyLengthRule: StrictTransferForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictTransferForecast) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictTransferForecastAllowedCurrencyRule: StrictTransferForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictTransferForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a strict transfer forecast.
    final class StrictTransferForecastValidator {
        var rules: [any StrictTransferForecastRule]

        init(rules: [any StrictTransferForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictTransferForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictTransferForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictTransferForecast]) -> [String: [String]] {
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

    static func defaultStrictTransferForecastValidator() -> StrictTransferForecastValidator {
        return StrictTransferForecastValidator(
            rules: [
                StrictTransferForecastRequiredCodeRule(message: "strict transfer forecast needs this field"),
                StrictTransferForecastCurrencyLengthRule(maxLength: 80),
                StrictTransferForecastAllowedCurrencyRule(allowed: ["scheduled", "fallback"]),
            ]
        )
    }
}
