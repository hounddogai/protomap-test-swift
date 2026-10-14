import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary rule must pass. Check returns its problems, or none.
    protocol FormularyRuleRule {
        func check(_ item: FormularyRule) -> [String]
    }

    final class FormularyRuleRequiredCodeRule: FormularyRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyRuleNameLengthRule: FormularyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyRuleCodeLengthRule: FormularyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyRuleAcuityRangeRule: FormularyRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyRule) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary rule.
    final class FormularyRuleValidator {
        var rules: [any FormularyRuleRule]

        init(rules: [any FormularyRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyRule]) -> [String: [String]] {
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

    static func defaultFormularyRuleValidator() -> FormularyRuleValidator {
        return FormularyRuleValidator(
            rules: [
                FormularyRuleRequiredCodeRule(message: "formulary rule needs an entry"),
                FormularyRuleNameLengthRule(maxLength: 80),
                FormularyRuleCodeLengthRule(maxLength: 3600),
                FormularyRuleAcuityRangeRule(min: 1000, max: 1000),
            ]
        )
    }
}
