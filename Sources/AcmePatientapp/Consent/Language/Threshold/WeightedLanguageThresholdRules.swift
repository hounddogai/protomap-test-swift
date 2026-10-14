import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted language threshold must pass. Check returns its problems, or none.
    protocol WeightedLanguageThresholdRule {
        func check(_ item: WeightedLanguageThreshold) -> [String]
    }

    final class WeightedLanguageThresholdRequiredNameRule: WeightedLanguageThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedLanguageThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedLanguageThresholdRequiredCodeRule: WeightedLanguageThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedLanguageThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedLanguageThresholdMaximumRangeRule: WeightedLanguageThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedLanguageThreshold) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted language threshold.
    final class WeightedLanguageThresholdValidator {
        var rules: [any WeightedLanguageThresholdRule]

        init(rules: [any WeightedLanguageThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedLanguageThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedLanguageThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedLanguageThreshold]) -> [String: [String]] {
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

    static func defaultWeightedLanguageThresholdValidator() -> WeightedLanguageThresholdValidator {
        return WeightedLanguageThresholdValidator(
            rules: [
                WeightedLanguageThresholdRequiredNameRule(message: "weighted language threshold needs an entry"),
                WeightedLanguageThresholdRequiredCodeRule(message: "weighted language threshold needs an entry"),
                WeightedLanguageThresholdMaximumRangeRule(min: 3.3, max: 4988.4),
            ]
        )
    }
}
