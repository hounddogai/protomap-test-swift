import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary policy must pass. Check returns its problems, or none.
    protocol FormularyPolicyRule {
        func check(_ item: FormularyPolicy) -> [String]
    }

    final class FormularyPolicyRequiredCodeRule: FormularyPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyPolicyRequiredPayerRule: FormularyPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyPolicy) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyPolicyLabelLengthRule: FormularyPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary policy.
    final class FormularyPolicyValidator {
        var rules: [any FormularyPolicyRule]

        init(rules: [any FormularyPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyPolicy]) -> [String: [String]] {
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

    static func defaultFormularyPolicyValidator() -> FormularyPolicyValidator {
        return FormularyPolicyValidator(
            rules: [
                FormularyPolicyRequiredCodeRule(message: "formulary policy needs an entry"),
                FormularyPolicyRequiredPayerRule(message: "formulary policy needs a value"),
                FormularyPolicyLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
