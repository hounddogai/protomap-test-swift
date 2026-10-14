import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol budget must pass. Check returns its problems, or none.
    protocol CareProtocolBudgetRule {
        func check(_ item: CareProtocolBudget) -> [String]
    }

    final class CareProtocolBudgetNotesLengthRule: CareProtocolBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolBudget) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolBudgetRequiredNotesRule: CareProtocolBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolBudget) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolBudgetCodeLengthRule: CareProtocolBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolBudgetRequiredCodeRule: CareProtocolBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolBudgetRequiredNameRule: CareProtocolBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolBudgetLimitRangeRule: CareProtocolBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolBudget) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol budget.
    final class CareProtocolBudgetValidator {
        var rules: [any CareProtocolBudgetRule]

        init(rules: [any CareProtocolBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolBudget]) -> [String: [String]] {
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

    static func defaultCareProtocolBudgetValidator() -> CareProtocolBudgetValidator {
        return CareProtocolBudgetValidator(
            rules: [
                CareProtocolBudgetNotesLengthRule(maxLength: 120),
                CareProtocolBudgetRequiredNotesRule(message: "care protocol budget needs this field"),
                CareProtocolBudgetCodeLengthRule(maxLength: 255),
                CareProtocolBudgetRequiredCodeRule(message: "care protocol budget needs a value"),
                CareProtocolBudgetRequiredNameRule(message: "care protocol budget needs an entry"),
                CareProtocolBudgetLimitRangeRule(min: 16, max: 64),
            ]
        )
    }
}
