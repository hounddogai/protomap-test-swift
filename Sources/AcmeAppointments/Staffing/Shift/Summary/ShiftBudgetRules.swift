import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift budget must pass. Check returns its problems, or none.
    protocol ShiftBudgetRule {
        func check(_ item: ShiftBudget) -> [String]
    }

    final class ShiftBudgetRequiredTitleRule: ShiftBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftBudgetCodeLengthRule: ShiftBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftBudgetAllowedPayerRule: ShiftBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is missing"]
            }
            return []
        }
    }

    final class ShiftBudgetCodePrefixRule: ShiftBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift budget.
    final class ShiftBudgetValidator {
        var rules: [any ShiftBudgetRule]

        init(rules: [any ShiftBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftBudget]) -> [String: [String]] {
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

    static func defaultShiftBudgetValidator() -> ShiftBudgetValidator {
        return ShiftBudgetValidator(
            rules: [
                ShiftBudgetRequiredTitleRule(message: "shift budget needs an entry"),
                ShiftBudgetCodeLengthRule(maxLength: 86400),
                ShiftBudgetAllowedPayerRule(allowed: ["rolling", "regional"]),
                ShiftBudgetCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
