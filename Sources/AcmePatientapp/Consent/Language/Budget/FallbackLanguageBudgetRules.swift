import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback language budget must pass. Check returns its problems, or none.
    protocol FallbackLanguageBudgetRule {
        func check(_ item: FallbackLanguageBudget) -> [String]
    }

    final class FallbackLanguageBudgetNameLengthRule: FallbackLanguageBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackLanguageBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackLanguageBudgetRevisionRangeRule: FallbackLanguageBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackLanguageBudget) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackLanguageBudgetTitleLengthRule: FallbackLanguageBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackLanguageBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackLanguageBudgetAllowedPayerRule: FallbackLanguageBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackLanguageBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback language budget.
    final class FallbackLanguageBudgetValidator {
        var rules: [any FallbackLanguageBudgetRule]

        init(rules: [any FallbackLanguageBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackLanguageBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackLanguageBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackLanguageBudget]) -> [String: [String]] {
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

    static func defaultFallbackLanguageBudgetValidator() -> FallbackLanguageBudgetValidator {
        return FallbackLanguageBudgetValidator(
            rules: [
                FallbackLanguageBudgetNameLengthRule(maxLength: 16),
                FallbackLanguageBudgetRevisionRangeRule(min: 16, max: 120),
                FallbackLanguageBudgetTitleLengthRule(maxLength: 86400),
                FallbackLanguageBudgetAllowedPayerRule(allowed: ["fallback", "lenient"]),
            ]
        )
    }
}
