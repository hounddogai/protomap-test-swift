import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language target must pass. Check returns its problems, or none.
    protocol LanguageTargetRule {
        func check(_ item: LanguageTarget) -> [String]
    }

    final class LanguageTargetCostRangeRule: LanguageTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageTarget) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageTargetRequiredProcedureCodeRule: LanguageTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageTarget) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageTargetRequiredCodeRule: LanguageTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageTargetCodeLengthRule: LanguageTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageTargetBudgetRangeRule: LanguageTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageTarget) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a language target.
    final class LanguageTargetValidator {
        var rules: [any LanguageTargetRule]

        init(rules: [any LanguageTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageTarget]) -> [String: [String]] {
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

    static func defaultLanguageTargetValidator() -> LanguageTargetValidator {
        return LanguageTargetValidator(
            rules: [
                LanguageTargetCostRangeRule(min: 7.5, max: 3878.6),
                LanguageTargetRequiredProcedureCodeRule(message: "language target needs a value"),
                LanguageTargetRequiredCodeRule(message: "language target needs a value"),
                LanguageTargetCodeLengthRule(maxLength: 86400),
                LanguageTargetBudgetRangeRule(min: 3.2, max: 1909.0),
            ]
        )
    }
}
