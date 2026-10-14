import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary preference must pass. Check returns its problems, or none.
    protocol FormularyPreferenceRule {
        func check(_ item: FormularyPreference) -> [String]
    }

    final class FormularyPreferenceCodeLengthRule: FormularyPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyPreferenceCodePrefixRule: FormularyPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FormularyPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FormularyPreferenceUnitLengthRule: FormularyPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyPreference) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyPreferenceExternalRefLengthRule: FormularyPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyPreference) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyPreferenceRequiredCodeRule: FormularyPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyPreferenceAllowedUnitRule: FormularyPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FormularyPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary preference.
    final class FormularyPreferenceValidator {
        var rules: [any FormularyPreferenceRule]

        init(rules: [any FormularyPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyPreference) -> [String] {
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

        func requireValid(_ item: FormularyPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyPreference]) -> [String: [String]] {
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

    static func defaultFormularyPreferenceValidator() -> FormularyPreferenceValidator {
        return FormularyPreferenceValidator(
            rules: [
                FormularyPreferenceCodeLengthRule(maxLength: 86400),
                FormularyPreferenceCodePrefixRule(prefix: "REF"),
                FormularyPreferenceUnitLengthRule(maxLength: 255),
                FormularyPreferenceExternalRefLengthRule(maxLength: 3600),
                FormularyPreferenceRequiredCodeRule(message: "formulary preference needs an entry"),
                FormularyPreferenceAllowedUnitRule(allowed: ["primary", "strict", "rolling"]),
            ]
        )
    }
}
