import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary float pool budget must pass. Check returns its problems, or none.
    protocol PrimaryFloatPoolBudgetRule {
        func check(_ item: PrimaryFloatPoolBudget) -> [String]
    }

    final class PrimaryFloatPoolBudgetCodeLengthRule: PrimaryFloatPoolBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFloatPoolBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryFloatPoolBudgetCodePrefixRule: PrimaryFloatPoolBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryFloatPoolBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryFloatPoolBudgetRequiredNameRule: PrimaryFloatPoolBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryFloatPoolBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryFloatPoolBudgetNameLengthRule: PrimaryFloatPoolBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFloatPoolBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryFloatPoolBudgetGraceDaysRangeRule: PrimaryFloatPoolBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryFloatPoolBudget) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary float pool budget.
    final class PrimaryFloatPoolBudgetValidator {
        var rules: [any PrimaryFloatPoolBudgetRule]

        init(rules: [any PrimaryFloatPoolBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryFloatPoolBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryFloatPoolBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryFloatPoolBudget]) -> [String: [String]] {
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

    static func defaultPrimaryFloatPoolBudgetValidator() -> PrimaryFloatPoolBudgetValidator {
        return PrimaryFloatPoolBudgetValidator(
            rules: [
                PrimaryFloatPoolBudgetCodeLengthRule(maxLength: 16),
                PrimaryFloatPoolBudgetCodePrefixRule(prefix: "ACM"),
                PrimaryFloatPoolBudgetRequiredNameRule(message: "primary float pool budget needs this field"),
                PrimaryFloatPoolBudgetNameLengthRule(maxLength: 32),
                PrimaryFloatPoolBudgetGraceDaysRangeRule(min: 64, max: 255),
            ]
        )
    }
}
