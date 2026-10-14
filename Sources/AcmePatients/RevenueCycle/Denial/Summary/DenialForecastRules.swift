import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial forecast must pass. Check returns its problems, or none.
    protocol DenialForecastRule {
        func check(_ item: DenialForecast) -> [String]
    }

    final class DenialForecastRequiredNameRule: DenialForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialForecastCodePrefixRule: DenialForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialForecastRequiredChannelRule: DenialForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialForecast) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialForecastRetriesRangeRule: DenialForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialForecast) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a denial forecast.
    final class DenialForecastValidator {
        var rules: [any DenialForecastRule]

        init(rules: [any DenialForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialForecast]) -> [String: [String]] {
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

    static func defaultDenialForecastValidator() -> DenialForecastValidator {
        return DenialForecastValidator(
            rules: [
                DenialForecastRequiredNameRule(message: "denial forecast needs a value"),
                DenialForecastCodePrefixRule(prefix: "Q"),
                DenialForecastRequiredChannelRule(message: "denial forecast needs a value"),
                DenialForecastRetriesRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
