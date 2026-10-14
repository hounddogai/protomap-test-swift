import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization forecast must pass. Check returns its problems, or none.
    protocol AuthorizationForecastRule {
        func check(_ item: AuthorizationForecast) -> [String]
    }

    final class AuthorizationForecastUpdatedAtRangeRule: AuthorizationForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationForecast) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationForecastCodePrefixRule: AuthorizationForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationForecastPatientRefLengthRule: AuthorizationForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationForecast) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization forecast.
    final class AuthorizationForecastValidator {
        var rules: [any AuthorizationForecastRule]

        init(rules: [any AuthorizationForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationForecast) -> [String] {
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

        func requireValid(_ item: AuthorizationForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationForecast]) -> [String: [String]] {
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

    static func defaultAuthorizationForecastValidator() -> AuthorizationForecastValidator {
        return AuthorizationForecastValidator(
            rules: [
                AuthorizationForecastUpdatedAtRangeRule(min: 1000, max: 3600),
                AuthorizationForecastCodePrefixRule(prefix: "REF"),
                AuthorizationForecastPatientRefLengthRule(maxLength: 1000),
            ]
        )
    }
}
