import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending read budget must pass. Check returns its problems, or none.
    protocol PendingReadBudgetRule {
        func check(_ item: PendingReadBudget) -> [String]
    }

    final class PendingReadBudgetRequiredNameRule: PendingReadBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReadBudgetCodeLengthRule: PendingReadBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReadBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReadBudgetCodePrefixRule: PendingReadBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingReadBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingReadBudgetRequiredCodeRule: PendingReadBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReadBudgetRequiredSourceRule: PendingReadBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadBudget) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReadBudgetChannelLengthRule: PendingReadBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReadBudget) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending read budget.
    final class PendingReadBudgetValidator {
        var rules: [any PendingReadBudgetRule]

        init(rules: [any PendingReadBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReadBudget) -> [String] {
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

        func requireValid(_ item: PendingReadBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReadBudget]) -> [String: [String]] {
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

    static func defaultPendingReadBudgetValidator() -> PendingReadBudgetValidator {
        return PendingReadBudgetValidator(
            rules: [
                PendingReadBudgetRequiredNameRule(message: "pending read budget needs this field"),
                PendingReadBudgetCodeLengthRule(maxLength: 80),
                PendingReadBudgetCodePrefixRule(prefix: "X"),
                PendingReadBudgetRequiredCodeRule(message: "pending read budget needs a value"),
                PendingReadBudgetRequiredSourceRule(message: "pending read budget needs a value"),
                PendingReadBudgetChannelLengthRule(maxLength: 32),
            ]
        )
    }
}
