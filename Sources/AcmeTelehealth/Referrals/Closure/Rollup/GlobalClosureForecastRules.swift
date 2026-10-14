import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global closure forecast must pass. Check returns its problems, or none.
    protocol GlobalClosureForecastRule {
        func check(_ item: GlobalClosureForecast) -> [String]
    }

    final class GlobalClosureForecastRequiredTitleRule: GlobalClosureForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalClosureForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalClosureForecastRevisionRangeRule: GlobalClosureForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalClosureForecast) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalClosureForecastCodeLengthRule: GlobalClosureForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalClosureForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalClosureForecastAllowedCodeRule: GlobalClosureForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalClosureForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a global closure forecast.
    final class GlobalClosureForecastValidator {
        var rules: [any GlobalClosureForecastRule]

        init(rules: [any GlobalClosureForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalClosureForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalClosureForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalClosureForecast]) -> [String: [String]] {
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

    static func defaultGlobalClosureForecastValidator() -> GlobalClosureForecastValidator {
        return GlobalClosureForecastValidator(
            rules: [
                GlobalClosureForecastRequiredTitleRule(message: "global closure forecast needs an entry"),
                GlobalClosureForecastRevisionRangeRule(min: 32, max: 64),
                GlobalClosureForecastCodeLengthRule(maxLength: 3600),
                GlobalClosureForecastAllowedCodeRule(allowed: []),
            ]
        )
    }
}
