import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert forecast must pass. Check returns its problems, or none.
    protocol AlertForecastRule {
        func check(_ item: AlertForecast) -> [String]
    }

    final class AlertForecastRequiredTitleRule: AlertForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertForecastCodePrefixRule: AlertForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertForecastVisibleGuardRule: AlertForecastRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AlertForecast) -> [String] {
            if item.visible && (item.endsAt > limit) {
                return ["ends at \(item.endsAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class AlertForecastRequiredCodeRule: AlertForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertForecastRevisionRangeRule: AlertForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertForecast) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert forecast.
    final class AlertForecastValidator {
        var rules: [any AlertForecastRule]

        init(rules: [any AlertForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertForecast]) -> [String: [String]] {
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

    static func defaultAlertForecastValidator() -> AlertForecastValidator {
        return AlertForecastValidator(
            rules: [
                AlertForecastRequiredTitleRule(message: "alert forecast needs this field"),
                AlertForecastCodePrefixRule(prefix: "ACM"),
                AlertForecastVisibleGuardRule(limit: 86400),
                AlertForecastRequiredCodeRule(message: "alert forecast needs a value"),
                AlertForecastRevisionRangeRule(min: 16, max: 80),
            ]
        )
    }
}
