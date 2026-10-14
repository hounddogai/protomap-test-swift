import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial budget must pass. Check returns its problems, or none.
    protocol DenialBudgetRule {
        func check(_ item: DenialBudget) -> [String]
    }

    final class DenialBudgetChecksumLengthRule: DenialBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialBudget) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialBudgetRequiredChecksumRule: DenialBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialBudget) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialBudgetTitleLengthRule: DenialBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialBudgetRequiredCodeRule: DenialBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialBudgetRequiredTitleRule: DenialBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial budget.
    final class DenialBudgetValidator {
        var rules: [any DenialBudgetRule]

        init(rules: [any DenialBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialBudget) -> [String] {
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

        func requireValid(_ item: DenialBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialBudget]) -> [String: [String]] {
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

    static func defaultDenialBudgetValidator() -> DenialBudgetValidator {
        return DenialBudgetValidator(
            rules: [
                DenialBudgetChecksumLengthRule(maxLength: 64),
                DenialBudgetRequiredChecksumRule(message: "denial budget needs an entry"),
                DenialBudgetTitleLengthRule(maxLength: 1000),
                DenialBudgetRequiredCodeRule(message: "denial budget needs this field"),
                DenialBudgetRequiredTitleRule(message: "denial budget needs this field"),
            ]
        )
    }
}
