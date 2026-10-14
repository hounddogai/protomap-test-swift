import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient authorization variance must pass. Check returns its problems, or none.
    protocol LenientAuthorizationVarianceRule {
        func check(_ item: LenientAuthorizationVariance) -> [String]
    }

    final class LenientAuthorizationVarianceRateRangeRule: LenientAuthorizationVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAuthorizationVariance) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientAuthorizationVarianceRequiredTitleRule: LenientAuthorizationVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAuthorizationVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAuthorizationVarianceCeilingRangeRule: LenientAuthorizationVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAuthorizationVariance) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientAuthorizationVarianceRequiredCodeRule: LenientAuthorizationVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAuthorizationVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient authorization variance.
    final class LenientAuthorizationVarianceValidator {
        var rules: [any LenientAuthorizationVarianceRule]

        init(rules: [any LenientAuthorizationVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientAuthorizationVariance) -> [String] {
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

        func requireValid(_ item: LenientAuthorizationVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientAuthorizationVariance]) -> [String: [String]] {
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

    static func defaultLenientAuthorizationVarianceValidator() -> LenientAuthorizationVarianceValidator {
        return LenientAuthorizationVarianceValidator(
            rules: [
                LenientAuthorizationVarianceRateRangeRule(min: 3.2, max: 3721.4),
                LenientAuthorizationVarianceRequiredTitleRule(
                    message: "lenient authorization variance needs an entry"
                ),
                LenientAuthorizationVarianceCeilingRangeRule(min: 4.2, max: 237.4),
                LenientAuthorizationVarianceRequiredCodeRule(message: "lenient authorization variance needs an entry"),
            ]
        )
    }
}
