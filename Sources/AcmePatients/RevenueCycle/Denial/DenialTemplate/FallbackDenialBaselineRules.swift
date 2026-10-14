import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback denial baseline must pass. Check returns its problems, or none.
    protocol FallbackDenialBaselineRule {
        func check(_ item: FallbackDenialBaseline) -> [String]
    }

    final class FallbackDenialBaselineRequiredExternalRefRule: FallbackDenialBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDenialBaseline) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDenialBaselineRequiredCodeRule: FallbackDenialBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDenialBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDenialBaselineRequiredNameRule: FallbackDenialBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDenialBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback denial baseline.
    final class FallbackDenialBaselineValidator {
        var rules: [any FallbackDenialBaselineRule]

        init(rules: [any FallbackDenialBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDenialBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackDenialBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDenialBaseline]) -> [String: [String]] {
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

    static func defaultFallbackDenialBaselineValidator() -> FallbackDenialBaselineValidator {
        return FallbackDenialBaselineValidator(
            rules: [
                FallbackDenialBaselineRequiredExternalRefRule(message: "fallback denial baseline needs this field"),
                FallbackDenialBaselineRequiredCodeRule(message: "fallback denial baseline needs an entry"),
                FallbackDenialBaselineRequiredNameRule(message: "fallback denial baseline needs a value"),
            ]
        )
    }
}
