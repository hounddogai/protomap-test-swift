import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive denial forecast must pass. Check returns its problems, or none.
    protocol AdaptiveDenialForecastRule {
        func check(_ item: AdaptiveDenialForecast) -> [String]
    }

    final class AdaptiveDenialForecastCodePrefixRule: AdaptiveDenialForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveDenialForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveDenialForecastLabelLengthRule: AdaptiveDenialForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDenialForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDenialForecastRequiredCurrencyRule: AdaptiveDenialForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDenialForecast) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDenialForecastRequiredCodeRule: AdaptiveDenialForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDenialForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDenialForecastRequiredLocaleRule: AdaptiveDenialForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDenialForecast) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDenialForecastDurationMinutesRangeRule: AdaptiveDenialForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveDenialForecast) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive denial forecast.
    final class AdaptiveDenialForecastValidator {
        var rules: [any AdaptiveDenialForecastRule]

        init(rules: [any AdaptiveDenialForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDenialForecast) -> [String] {
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

        func requireValid(_ item: AdaptiveDenialForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDenialForecast]) -> [String: [String]] {
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

    static func defaultAdaptiveDenialForecastValidator() -> AdaptiveDenialForecastValidator {
        return AdaptiveDenialForecastValidator(
            rules: [
                AdaptiveDenialForecastCodePrefixRule(prefix: "ACM"),
                AdaptiveDenialForecastLabelLengthRule(maxLength: 64),
                AdaptiveDenialForecastRequiredCurrencyRule(message: "adaptive denial forecast needs an entry"),
                AdaptiveDenialForecastRequiredCodeRule(message: "adaptive denial forecast needs a value"),
                AdaptiveDenialForecastRequiredLocaleRule(message: "adaptive denial forecast needs a value"),
                AdaptiveDenialForecastDurationMinutesRangeRule(min: 80, max: 120),
            ]
        )
    }
}
