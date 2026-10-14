import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback charge exception must pass. Check returns its problems, or none.
    protocol FallbackChargeExceptionRule {
        func check(_ item: FallbackChargeException) -> [String]
    }

    final class FallbackChargeExceptionRequiredTitleRule: FallbackChargeExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackChargeException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackChargeExceptionMarginRangeRule: FallbackChargeExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackChargeException) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackChargeExceptionCodePrefixRule: FallbackChargeExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackChargeException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback charge exception.
    final class FallbackChargeExceptionValidator {
        var rules: [any FallbackChargeExceptionRule]

        init(rules: [any FallbackChargeExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackChargeException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackChargeException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackChargeException]) -> [String: [String]] {
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

    static func defaultFallbackChargeExceptionValidator() -> FallbackChargeExceptionValidator {
        return FallbackChargeExceptionValidator(
            rules: [
                FallbackChargeExceptionRequiredTitleRule(message: "fallback charge exception needs a value"),
                FallbackChargeExceptionMarginRangeRule(min: 9.3, max: 900.2),
                FallbackChargeExceptionCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
