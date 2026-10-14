import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary template must pass. Check returns its problems, or none.
    protocol FormularyTemplateRule {
        func check(_ item: FormularyTemplate) -> [String]
    }

    final class FormularyTemplateDiagnosisCodeLengthRule: FormularyTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyTemplate) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyTemplateCodeLengthRule: FormularyTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyTemplateGraceDaysRangeRule: FormularyTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyTemplate) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularyTemplateCodePrefixRule: FormularyTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FormularyTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary template.
    final class FormularyTemplateValidator {
        var rules: [any FormularyTemplateRule]

        init(rules: [any FormularyTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyTemplate) -> [String] {
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

        func requireValid(_ item: FormularyTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyTemplate]) -> [String: [String]] {
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

    static func defaultFormularyTemplateValidator() -> FormularyTemplateValidator {
        return FormularyTemplateValidator(
            rules: [
                FormularyTemplateDiagnosisCodeLengthRule(maxLength: 32),
                FormularyTemplateCodeLengthRule(maxLength: 64),
                FormularyTemplateGraceDaysRangeRule(min: 16, max: 86400),
                FormularyTemplateCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
