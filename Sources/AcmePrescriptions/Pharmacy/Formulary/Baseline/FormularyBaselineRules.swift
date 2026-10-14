import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary baseline must pass. Check returns its problems, or none.
    protocol FormularyBaselineRule {
        func check(_ item: FormularyBaseline) -> [String]
    }

    final class FormularyBaselineCodeLengthRule: FormularyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyBaselineCodePrefixRule: FormularyBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FormularyBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FormularyBaselineRequiredTitleRule: FormularyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyBaselineAllowedTitleRule: FormularyBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FormularyBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class FormularyBaselinePayerLengthRule: FormularyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyBaseline) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary baseline.
    final class FormularyBaselineValidator {
        var rules: [any FormularyBaselineRule]

        init(rules: [any FormularyBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyBaseline) -> [String] {
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

        func requireValid(_ item: FormularyBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyBaseline]) -> [String: [String]] {
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

    static func defaultFormularyBaselineValidator() -> FormularyBaselineValidator {
        return FormularyBaselineValidator(
            rules: [
                FormularyBaselineCodeLengthRule(maxLength: 32),
                FormularyBaselineCodePrefixRule(prefix: "OPS"),
                FormularyBaselineRequiredTitleRule(message: "formulary baseline needs a value"),
                FormularyBaselineAllowedTitleRule(allowed: ["manual", "regional", "seasonal"]),
                FormularyBaselinePayerLengthRule(maxLength: 86400),
            ]
        )
    }
}
