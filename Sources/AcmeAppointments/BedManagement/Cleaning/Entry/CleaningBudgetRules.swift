import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning budget must pass. Check returns its problems, or none.
    protocol CleaningBudgetRule {
        func check(_ item: CleaningBudget) -> [String]
    }

    final class CleaningBudgetCodeLengthRule: CleaningBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningBudgetRequiredSummaryRule: CleaningBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningBudget) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningBudgetEndsAtRangeRule: CleaningBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningBudget) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningBudgetRequiredCodeRule: CleaningBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningBudgetCodePrefixRule: CleaningBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CleaningBudgetRequiredNameRule: CleaningBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning budget.
    final class CleaningBudgetValidator {
        var rules: [any CleaningBudgetRule]

        init(rules: [any CleaningBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningBudget]) -> [String: [String]] {
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

    static func defaultCleaningBudgetValidator() -> CleaningBudgetValidator {
        return CleaningBudgetValidator(
            rules: [
                CleaningBudgetCodeLengthRule(maxLength: 64),
                CleaningBudgetRequiredSummaryRule(message: "cleaning budget needs this field"),
                CleaningBudgetEndsAtRangeRule(min: 64, max: 86400),
                CleaningBudgetRequiredCodeRule(message: "cleaning budget needs this field"),
                CleaningBudgetCodePrefixRule(prefix: "Q"),
                CleaningBudgetRequiredNameRule(message: "cleaning budget needs this field"),
            ]
        )
    }
}
