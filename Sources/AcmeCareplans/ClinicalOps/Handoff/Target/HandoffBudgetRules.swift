import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff budget must pass. Check returns its problems, or none.
    protocol HandoffBudgetRule {
        func check(_ item: HandoffBudget) -> [String]
    }

    final class HandoffBudgetRequiredCodeRule: HandoffBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffBudgetMinimumRangeRule: HandoffBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffBudget) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffBudgetWardLengthRule: HandoffBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffBudget) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffBudgetNameLengthRule: HandoffBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffBudgetDiagnosisCodeLengthRule: HandoffBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffBudget) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffBudgetRequiredWardRule: HandoffBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffBudget) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a handoff budget.
    final class HandoffBudgetValidator {
        var rules: [any HandoffBudgetRule]

        init(rules: [any HandoffBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffBudget]) -> [String: [String]] {
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

    static func defaultHandoffBudgetValidator() -> HandoffBudgetValidator {
        return HandoffBudgetValidator(
            rules: [
                HandoffBudgetRequiredCodeRule(message: "handoff budget needs this field"),
                HandoffBudgetMinimumRangeRule(min: 1.9, max: 1065.7),
                HandoffBudgetWardLengthRule(maxLength: 32),
                HandoffBudgetNameLengthRule(maxLength: 64),
                HandoffBudgetDiagnosisCodeLengthRule(maxLength: 1000),
                HandoffBudgetRequiredWardRule(message: "handoff budget needs an entry"),
            ]
        )
    }
}
