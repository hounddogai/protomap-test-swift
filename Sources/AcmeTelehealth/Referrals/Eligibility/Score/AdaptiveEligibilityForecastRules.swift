import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive eligibility forecast must pass. Check returns its problems, or none.
    protocol AdaptiveEligibilityForecastRule {
        func check(_ item: AdaptiveEligibilityForecast) -> [String]
    }

    final class AdaptiveEligibilityForecastCodePrefixRule: AdaptiveEligibilityForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveEligibilityForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveEligibilityForecastCreatedAtRangeRule: AdaptiveEligibilityForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveEligibilityForecast) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveEligibilityForecastNameLengthRule: AdaptiveEligibilityForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveEligibilityForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive eligibility forecast.
    final class AdaptiveEligibilityForecastValidator {
        var rules: [any AdaptiveEligibilityForecastRule]

        init(rules: [any AdaptiveEligibilityForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveEligibilityForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveEligibilityForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveEligibilityForecast]) -> [String: [String]] {
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

    static func defaultAdaptiveEligibilityForecastValidator() -> AdaptiveEligibilityForecastValidator {
        return AdaptiveEligibilityForecastValidator(
            rules: [
                AdaptiveEligibilityForecastCodePrefixRule(prefix: "Q"),
                AdaptiveEligibilityForecastCreatedAtRangeRule(min: 16, max: 255),
                AdaptiveEligibilityForecastNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
