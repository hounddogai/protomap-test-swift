import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language request must pass. Check returns its problems, or none.
    protocol LanguageRequestRule {
        func check(_ item: LanguageRequest) -> [String]
    }

    final class LanguageRequestAllowedCountryRule: LanguageRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is expired"]
            }
            return []
        }
    }

    final class LanguageRequestWeightRangeRule: LanguageRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageRequest) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageRequestRequiredCodeRule: LanguageRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language request.
    final class LanguageRequestValidator {
        var rules: [any LanguageRequestRule]

        init(rules: [any LanguageRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageRequest]) -> [String: [String]] {
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

    static func defaultLanguageRequestValidator() -> LanguageRequestValidator {
        return LanguageRequestValidator(
            rules: [
                LanguageRequestAllowedCountryRule(allowed: ["batched", "regional", "rolling"]),
                LanguageRequestWeightRangeRule(min: 1.0, max: 3470.2),
                LanguageRequestRequiredCodeRule(message: "language request needs a value"),
            ]
        )
    }
}
