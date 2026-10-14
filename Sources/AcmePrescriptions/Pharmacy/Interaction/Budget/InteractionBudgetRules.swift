import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction budget must pass. Check returns its problems, or none.
    protocol InteractionBudgetRule {
        func check(_ item: InteractionBudget) -> [String]
    }

    final class InteractionBudgetChecksumLengthRule: InteractionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionBudget) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionBudgetMaximumRangeRule: InteractionBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionBudget) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionBudgetRequiredTitleRule: InteractionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionBudgetRequiredChecksumRule: InteractionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionBudget) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionBudgetRequiredCodeRule: InteractionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction budget.
    final class InteractionBudgetValidator {
        var rules: [any InteractionBudgetRule]

        init(rules: [any InteractionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionBudget]) -> [String: [String]] {
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

    static func defaultInteractionBudgetValidator() -> InteractionBudgetValidator {
        return InteractionBudgetValidator(
            rules: [
                InteractionBudgetChecksumLengthRule(maxLength: 255),
                InteractionBudgetMaximumRangeRule(min: 3.1, max: 4516.4),
                InteractionBudgetRequiredTitleRule(message: "interaction budget needs an entry"),
                InteractionBudgetRequiredChecksumRule(message: "interaction budget needs a value"),
                InteractionBudgetRequiredCodeRule(message: "interaction budget needs a value"),
            ]
        )
    }
}
