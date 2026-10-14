import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set budget must pass. Check returns its problems, or none.
    protocol OrderSetBudgetRule {
        func check(_ item: OrderSetBudget) -> [String]
    }

    final class OrderSetBudgetCodeLengthRule: OrderSetBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetBudgetAllowedOwnerIDRule: OrderSetBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is missing"]
            }
            return []
        }
    }

    final class OrderSetBudgetRequiredContactEmailRule: OrderSetBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetBudget) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetBudgetContactEmailLengthRule: OrderSetBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetBudget) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetBudgetCodePrefixRule: OrderSetBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set budget.
    final class OrderSetBudgetValidator {
        var rules: [any OrderSetBudgetRule]

        init(rules: [any OrderSetBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetBudget]) -> [String: [String]] {
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

    static func defaultOrderSetBudgetValidator() -> OrderSetBudgetValidator {
        return OrderSetBudgetValidator(
            rules: [
                OrderSetBudgetCodeLengthRule(maxLength: 16),
                OrderSetBudgetAllowedOwnerIDRule(allowed: ["adaptive", "strict"]),
                OrderSetBudgetRequiredContactEmailRule(message: "order set budget needs a value"),
                OrderSetBudgetContactEmailLengthRule(maxLength: 64),
                OrderSetBudgetCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
