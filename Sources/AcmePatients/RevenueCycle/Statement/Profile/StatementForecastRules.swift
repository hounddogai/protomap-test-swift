import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement forecast must pass. Check returns its problems, or none.
    protocol StatementForecastRule {
        func check(_ item: StatementForecast) -> [String]
    }

    final class StatementForecastAllowedTitleRule: StatementForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class StatementForecastRetriesRangeRule: StatementForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementForecast) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementForecastRequiredTitleRule: StatementForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementForecastAmountRangeRule: StatementForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementForecast) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementForecastTitleLengthRule: StatementForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementForecastCodePrefixRule: StatementForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement forecast.
    final class StatementForecastValidator {
        var rules: [any StatementForecastRule]

        init(rules: [any StatementForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementForecast]) -> [String: [String]] {
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

    static func defaultStatementForecastValidator() -> StatementForecastValidator {
        return StatementForecastValidator(
            rules: [
                StatementForecastAllowedTitleRule(allowed: []),
                StatementForecastRetriesRangeRule(min: 80, max: 120),
                StatementForecastRequiredTitleRule(message: "statement forecast needs a value"),
                StatementForecastAmountRangeRule(min: 1.3, max: 4306.5),
                StatementForecastTitleLengthRule(maxLength: 255),
                StatementForecastCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
