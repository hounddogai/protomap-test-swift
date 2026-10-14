import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global disclosure forecast must pass. Check returns its problems, or none.
    protocol GlobalDisclosureForecastRule {
        func check(_ item: GlobalDisclosureForecast) -> [String]
    }

    final class GlobalDisclosureForecastAllowedDiagnosisCodeRule: GlobalDisclosureForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalDisclosureForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is expired"]
            }
            return []
        }
    }

    final class GlobalDisclosureForecastRequiredLabelRule: GlobalDisclosureForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDisclosureForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDisclosureForecastRequiredDiagnosisCodeRule: GlobalDisclosureForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDisclosureForecast) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDisclosureForecastCreatedAtRangeRule: GlobalDisclosureForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDisclosureForecast) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global disclosure forecast.
    final class GlobalDisclosureForecastValidator {
        var rules: [any GlobalDisclosureForecastRule]

        init(rules: [any GlobalDisclosureForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDisclosureForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalDisclosureForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDisclosureForecast]) -> [String: [String]] {
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

    static func defaultGlobalDisclosureForecastValidator() -> GlobalDisclosureForecastValidator {
        return GlobalDisclosureForecastValidator(
            rules: [
                GlobalDisclosureForecastAllowedDiagnosisCodeRule(allowed: ["regional"]),
                GlobalDisclosureForecastRequiredLabelRule(message: "global disclosure forecast needs a value"),
                GlobalDisclosureForecastRequiredDiagnosisCodeRule(
                    message: "global disclosure forecast needs an entry"
                ),
                GlobalDisclosureForecastCreatedAtRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
