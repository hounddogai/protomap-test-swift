import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge budget must pass. Check returns its problems, or none.
    protocol ChargeBudgetRule {
        func check(_ item: ChargeBudget) -> [String]
    }

    final class ChargeBudgetPriorityRangeRule: ChargeBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeBudget) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeBudgetRequiredLocaleRule: ChargeBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeBudget) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeBudgetCodePrefixRule: ChargeBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeBudgetPinnedGuardRule: ChargeBudgetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ChargeBudget) -> [String] {
            if item.pinned && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class ChargeBudgetNameLengthRule: ChargeBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeBudgetRequiredContactEmailRule: ChargeBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeBudget) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge budget.
    final class ChargeBudgetValidator {
        var rules: [any ChargeBudgetRule]

        init(rules: [any ChargeBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeBudget]) -> [String: [String]] {
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

    static func defaultChargeBudgetValidator() -> ChargeBudgetValidator {
        return ChargeBudgetValidator(
            rules: [
                ChargeBudgetPriorityRangeRule(min: 32, max: 64),
                ChargeBudgetRequiredLocaleRule(message: "charge budget needs this field"),
                ChargeBudgetCodePrefixRule(prefix: "Q"),
                ChargeBudgetPinnedGuardRule(limit: 80),
                ChargeBudgetNameLengthRule(maxLength: 86400),
                ChargeBudgetRequiredContactEmailRule(message: "charge budget needs an entry"),
            ]
        )
    }
}
