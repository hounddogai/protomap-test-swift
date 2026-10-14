import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range budget must pass. Check returns its problems, or none.
    protocol ReferenceRangeBudgetRule {
        func check(_ item: ReferenceRangeBudget) -> [String]
    }

    final class ReferenceRangeBudgetRequiredCategoryRule: ReferenceRangeBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeBudget) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeBudgetWardLengthRule: ReferenceRangeBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeBudget) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeBudgetCategoryLengthRule: ReferenceRangeBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeBudget) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeBudgetLabelLengthRule: ReferenceRangeBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeBudget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range budget.
    final class ReferenceRangeBudgetValidator {
        var rules: [any ReferenceRangeBudgetRule]

        init(rules: [any ReferenceRangeBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeBudget]) -> [String: [String]] {
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

    static func defaultReferenceRangeBudgetValidator() -> ReferenceRangeBudgetValidator {
        return ReferenceRangeBudgetValidator(
            rules: [
                ReferenceRangeBudgetRequiredCategoryRule(message: "reference range budget needs a value"),
                ReferenceRangeBudgetWardLengthRule(maxLength: 255),
                ReferenceRangeBudgetCategoryLengthRule(maxLength: 80),
                ReferenceRangeBudgetLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
