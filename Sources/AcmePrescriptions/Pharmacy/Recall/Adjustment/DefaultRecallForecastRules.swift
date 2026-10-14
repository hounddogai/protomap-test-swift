import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default recall forecast must pass. Check returns its problems, or none.
    protocol DefaultRecallForecastRule {
        func check(_ item: DefaultRecallForecast) -> [String]
    }

    final class DefaultRecallForecastRequiredPayerRule: DefaultRecallForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRecallForecast) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRecallForecastRequiredTitleRule: DefaultRecallForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRecallForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRecallForecastRequiredCurrencyRule: DefaultRecallForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRecallForecast) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRecallForecastCurrencyLengthRule: DefaultRecallForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRecallForecast) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRecallForecastRequiredCodeRule: DefaultRecallForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRecallForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRecallForecastCodePrefixRule: DefaultRecallForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultRecallForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default recall forecast.
    final class DefaultRecallForecastValidator {
        var rules: [any DefaultRecallForecastRule]

        init(rules: [any DefaultRecallForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRecallForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRecallForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRecallForecast]) -> [String: [String]] {
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

    static func defaultDefaultRecallForecastValidator() -> DefaultRecallForecastValidator {
        return DefaultRecallForecastValidator(
            rules: [
                DefaultRecallForecastRequiredPayerRule(message: "default recall forecast needs a value"),
                DefaultRecallForecastRequiredTitleRule(message: "default recall forecast needs a value"),
                DefaultRecallForecastRequiredCurrencyRule(message: "default recall forecast needs this field"),
                DefaultRecallForecastCurrencyLengthRule(maxLength: 1000),
                DefaultRecallForecastRequiredCodeRule(message: "default recall forecast needs this field"),
                DefaultRecallForecastCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
