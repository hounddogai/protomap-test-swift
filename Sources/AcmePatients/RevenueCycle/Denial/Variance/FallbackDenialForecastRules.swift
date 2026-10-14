import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback denial forecast must pass. Check returns its problems, or none.
    protocol FallbackDenialForecastRule {
        func check(_ item: FallbackDenialForecast) -> [String]
    }

    final class FallbackDenialForecastCodePrefixRule: FallbackDenialForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackDenialForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackDenialForecastRequiredTitleRule: FallbackDenialForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDenialForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDenialForecastAllowedChannelRule: FallbackDenialForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackDenialForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is unknown"]
            }
            return []
        }
    }

    final class FallbackDenialForecastRatioRangeRule: FallbackDenialForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDenialForecast) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackDenialForecastCodeLengthRule: FallbackDenialForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDenialForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback denial forecast.
    final class FallbackDenialForecastValidator {
        var rules: [any FallbackDenialForecastRule]

        init(rules: [any FallbackDenialForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDenialForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackDenialForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDenialForecast]) -> [String: [String]] {
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

    static func defaultFallbackDenialForecastValidator() -> FallbackDenialForecastValidator {
        return FallbackDenialForecastValidator(
            rules: [
                FallbackDenialForecastCodePrefixRule(prefix: "OPS"),
                FallbackDenialForecastRequiredTitleRule(message: "fallback denial forecast needs an entry"),
                FallbackDenialForecastAllowedChannelRule(allowed: ["tiered"]),
                FallbackDenialForecastRatioRangeRule(min: 1.0, max: 2401.1),
                FallbackDenialForecastCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
