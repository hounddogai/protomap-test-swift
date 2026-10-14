import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language budget must pass. Check returns its problems, or none.
    protocol LanguageBudgetRule {
        func check(_ item: LanguageBudget) -> [String]
    }

    final class LanguageBudgetCodePrefixRule: LanguageBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageBudgetQuantityRangeRule: LanguageBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageBudget) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageBudgetNameLengthRule: LanguageBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageBudgetMinimumRangeRule: LanguageBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageBudget) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageBudgetAllowedNameRule: LanguageBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class LanguageBudgetRequiredCurrencyRule: LanguageBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageBudget) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language budget.
    final class LanguageBudgetValidator {
        var rules: [any LanguageBudgetRule]

        init(rules: [any LanguageBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageBudget) -> [String] {
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

        func requireValid(_ item: LanguageBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageBudget]) -> [String: [String]] {
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

    static func defaultLanguageBudgetValidator() -> LanguageBudgetValidator {
        return LanguageBudgetValidator(
            rules: [
                LanguageBudgetCodePrefixRule(prefix: "X"),
                LanguageBudgetQuantityRangeRule(min: 32, max: 120),
                LanguageBudgetNameLengthRule(maxLength: 120),
                LanguageBudgetMinimumRangeRule(min: 9.3, max: 1759.9),
                LanguageBudgetAllowedNameRule(allowed: ["batched", "legacy"]),
                LanguageBudgetRequiredCurrencyRule(message: "language budget needs this field"),
            ]
        )
    }
}
