import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict statement forecast must pass. Check returns its problems, or none.
    protocol StrictStatementForecastRule {
        func check(_ item: StrictStatementForecast) -> [String]
    }

    final class StrictStatementForecastCodePrefixRule: StrictStatementForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictStatementForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictStatementForecastAllowedSummaryRule: StrictStatementForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictStatementForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is out of range"]
            }
            return []
        }
    }

    final class StrictStatementForecastRequiredBedRule: StrictStatementForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictStatementForecast) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict statement forecast.
    final class StrictStatementForecastValidator {
        var rules: [any StrictStatementForecastRule]

        init(rules: [any StrictStatementForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictStatementForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictStatementForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictStatementForecast]) -> [String: [String]] {
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

    static func defaultStrictStatementForecastValidator() -> StrictStatementForecastValidator {
        return StrictStatementForecastValidator(
            rules: [
                StrictStatementForecastCodePrefixRule(prefix: "OPS"),
                StrictStatementForecastAllowedSummaryRule(allowed: []),
                StrictStatementForecastRequiredBedRule(message: "strict statement forecast needs this field"),
            ]
        )
    }
}
