import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted language request must pass. Check returns its problems, or none.
    protocol WeightedLanguageRequestRule {
        func check(_ item: WeightedLanguageRequest) -> [String]
    }

    final class WeightedLanguageRequestDiscountRangeRule: WeightedLanguageRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedLanguageRequest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedLanguageRequestRequiredCodeRule: WeightedLanguageRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedLanguageRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedLanguageRequestRequiredTitleRule: WeightedLanguageRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedLanguageRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted language request.
    final class WeightedLanguageRequestValidator {
        var rules: [any WeightedLanguageRequestRule]

        init(rules: [any WeightedLanguageRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedLanguageRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedLanguageRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedLanguageRequest]) -> [String: [String]] {
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

    static func defaultWeightedLanguageRequestValidator() -> WeightedLanguageRequestValidator {
        return WeightedLanguageRequestValidator(
            rules: [
                WeightedLanguageRequestDiscountRangeRule(min: 2.2, max: 3846.9),
                WeightedLanguageRequestRequiredCodeRule(message: "weighted language request needs a value"),
                WeightedLanguageRequestRequiredTitleRule(message: "weighted language request needs an entry"),
            ]
        )
    }
}
