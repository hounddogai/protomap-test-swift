import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language metric must pass. Check returns its problems, or none.
    protocol LanguageMetricRule {
        func check(_ item: LanguageMetric) -> [String]
    }

    final class LanguageMetricRequiredCountryRule: LanguageMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageMetric) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageMetricAttemptsRangeRule: LanguageMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageMetric) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageMetricAllowedNameRule: LanguageMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class LanguageMetricRequiredDiagnosisCodeRule: LanguageMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageMetric) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageMetricRequiredNameRule: LanguageMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageMetricRequiredCodeRule: LanguageMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language metric.
    final class LanguageMetricValidator {
        var rules: [any LanguageMetricRule]

        init(rules: [any LanguageMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageMetric) -> [String] {
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

        func requireValid(_ item: LanguageMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageMetric]) -> [String: [String]] {
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

    static func defaultLanguageMetricValidator() -> LanguageMetricValidator {
        return LanguageMetricValidator(
            rules: [
                LanguageMetricRequiredCountryRule(message: "language metric needs an entry"),
                LanguageMetricAttemptsRangeRule(min: 255, max: 86400),
                LanguageMetricAllowedNameRule(allowed: ["tiered", "primary", "pending"]),
                LanguageMetricRequiredDiagnosisCodeRule(message: "language metric needs a value"),
                LanguageMetricRequiredNameRule(message: "language metric needs this field"),
                LanguageMetricRequiredCodeRule(message: "language metric needs an entry"),
            ]
        )
    }
}
