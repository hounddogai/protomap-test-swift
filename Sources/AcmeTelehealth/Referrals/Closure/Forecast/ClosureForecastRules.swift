import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure forecast must pass. Check returns its problems, or none.
    protocol ClosureForecastRule {
        func check(_ item: ClosureForecast) -> [String]
    }

    final class ClosureForecastCodePrefixRule: ClosureForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClosureForecastAllowedTitleRule: ClosureForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    final class ClosureForecastRequiredCodeRule: ClosureForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureForecastAttemptsRangeRule: ClosureForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureForecast) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureForecastRequiredProcedureCodeRule: ClosureForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureForecast) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure forecast.
    final class ClosureForecastValidator {
        var rules: [any ClosureForecastRule]

        init(rules: [any ClosureForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureForecast]) -> [String: [String]] {
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

    static func defaultClosureForecastValidator() -> ClosureForecastValidator {
        return ClosureForecastValidator(
            rules: [
                ClosureForecastCodePrefixRule(prefix: "Q"),
                ClosureForecastAllowedTitleRule(allowed: ["fallback"]),
                ClosureForecastRequiredCodeRule(message: "closure forecast needs this field"),
                ClosureForecastAttemptsRangeRule(min: 64, max: 1000),
                ClosureForecastRequiredProcedureCodeRule(message: "closure forecast needs a value"),
            ]
        )
    }
}
