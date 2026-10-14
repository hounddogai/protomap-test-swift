import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback claim exception must pass. Check returns its problems, or none.
    protocol FallbackClaimExceptionRule {
        func check(_ item: FallbackClaimException) -> [String]
    }

    final class FallbackClaimExceptionRequiredNameRule: FallbackClaimExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClaimException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackClaimExceptionCodePrefixRule: FallbackClaimExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackClaimException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackClaimExceptionActiveGuardRule: FallbackClaimExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FallbackClaimException) -> [String] {
            if item.active && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class FallbackClaimExceptionPriorityRangeRule: FallbackClaimExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackClaimException) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback claim exception.
    final class FallbackClaimExceptionValidator {
        var rules: [any FallbackClaimExceptionRule]

        init(rules: [any FallbackClaimExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackClaimException) -> [String] {
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

        func requireValid(_ item: FallbackClaimException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackClaimException]) -> [String: [String]] {
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

    static func defaultFallbackClaimExceptionValidator() -> FallbackClaimExceptionValidator {
        return FallbackClaimExceptionValidator(
            rules: [
                FallbackClaimExceptionRequiredNameRule(message: "fallback claim exception needs a value"),
                FallbackClaimExceptionCodePrefixRule(prefix: "Q"),
                FallbackClaimExceptionActiveGuardRule(limit: 86400),
                FallbackClaimExceptionPriorityRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
