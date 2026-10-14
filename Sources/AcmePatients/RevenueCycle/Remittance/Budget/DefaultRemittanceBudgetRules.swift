import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default remittance budget must pass. Check returns its problems, or none.
    protocol DefaultRemittanceBudgetRule {
        func check(_ item: DefaultRemittanceBudget) -> [String]
    }

    final class DefaultRemittanceBudgetRequiredTitleRule: DefaultRemittanceBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRemittanceBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRemittanceBudgetRequiredCodeRule: DefaultRemittanceBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRemittanceBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRemittanceBudgetTitleLengthRule: DefaultRemittanceBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRemittanceBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRemittanceBudgetAllowedCodeRule: DefaultRemittanceBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultRemittanceBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class DefaultRemittanceBudgetCodePrefixRule: DefaultRemittanceBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultRemittanceBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultRemittanceBudgetCodeLengthRule: DefaultRemittanceBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRemittanceBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default remittance budget.
    final class DefaultRemittanceBudgetValidator {
        var rules: [any DefaultRemittanceBudgetRule]

        init(rules: [any DefaultRemittanceBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRemittanceBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRemittanceBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRemittanceBudget]) -> [String: [String]] {
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

    static func defaultDefaultRemittanceBudgetValidator() -> DefaultRemittanceBudgetValidator {
        return DefaultRemittanceBudgetValidator(
            rules: [
                DefaultRemittanceBudgetRequiredTitleRule(message: "default remittance budget needs this field"),
                DefaultRemittanceBudgetRequiredCodeRule(message: "default remittance budget needs an entry"),
                DefaultRemittanceBudgetTitleLengthRule(maxLength: 120),
                DefaultRemittanceBudgetAllowedCodeRule(allowed: ["legacy", "legacy", "fallback"]),
                DefaultRemittanceBudgetCodePrefixRule(prefix: "REF"),
                DefaultRemittanceBudgetCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
