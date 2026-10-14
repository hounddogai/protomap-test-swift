import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary entry must pass. Check returns its problems, or none.
    protocol FormularyEntryRule {
        func check(_ item: FormularyEntry) -> [String]
    }

    final class FormularyEntryRequiredExternalRefRule: FormularyEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyEntry) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyEntryAllowedCodeRule: FormularyEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FormularyEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class FormularyEntryMaximumRangeRule: FormularyEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyEntry) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyEntryExternalRefLengthRule: FormularyEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyEntry) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary entry.
    final class FormularyEntryValidator {
        var rules: [any FormularyEntryRule]

        init(rules: [any FormularyEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyEntry]) -> [String: [String]] {
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

    static func defaultFormularyEntryValidator() -> FormularyEntryValidator {
        return FormularyEntryValidator(
            rules: [
                FormularyEntryRequiredExternalRefRule(message: "formulary entry needs a value"),
                FormularyEntryAllowedCodeRule(allowed: ["legacy", "fallback", "manual"]),
                FormularyEntryMaximumRangeRule(min: 6.1, max: 2678.0),
                FormularyEntryExternalRefLengthRule(maxLength: 80),
            ]
        )
    }
}
