import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary override must pass. Check returns its problems, or none.
    protocol FormularyOverrideRule {
        func check(_ item: FormularyOverride) -> [String]
    }

    final class FormularyOverrideLabelLengthRule: FormularyOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyOverrideRequiredSourceRule: FormularyOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyOverride) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyOverrideRateRangeRule: FormularyOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyOverride) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary override.
    final class FormularyOverrideValidator {
        var rules: [any FormularyOverrideRule]

        init(rules: [any FormularyOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyOverride) -> [String] {
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

        func requireValid(_ item: FormularyOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyOverride]) -> [String: [String]] {
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

    static func defaultFormularyOverrideValidator() -> FormularyOverrideValidator {
        return FormularyOverrideValidator(
            rules: [
                FormularyOverrideLabelLengthRule(maxLength: 80),
                FormularyOverrideRequiredSourceRule(message: "formulary override needs a value"),
                FormularyOverrideRateRangeRule(min: 5.2, max: 4716.9),
            ]
        )
    }
}
