import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary group must pass. Check returns its problems, or none.
    protocol FormularyGroupRule {
        func check(_ item: FormularyGroup) -> [String]
    }

    final class FormularyGroupEndsAtRangeRule: FormularyGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyGroup) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularyGroupChecksumLengthRule: FormularyGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyGroup) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyGroupRequiredChecksumRule: FormularyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyGroup) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyGroupCodeLengthRule: FormularyGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyGroupCodePrefixRule: FormularyGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FormularyGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary group.
    final class FormularyGroupValidator {
        var rules: [any FormularyGroupRule]

        init(rules: [any FormularyGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyGroup) -> [String] {
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

        func requireValid(_ item: FormularyGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyGroup]) -> [String: [String]] {
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

    static func defaultFormularyGroupValidator() -> FormularyGroupValidator {
        return FormularyGroupValidator(
            rules: [
                FormularyGroupEndsAtRangeRule(min: 64, max: 1000),
                FormularyGroupChecksumLengthRule(maxLength: 16),
                FormularyGroupRequiredChecksumRule(message: "formulary group needs a value"),
                FormularyGroupCodeLengthRule(maxLength: 1000),
                FormularyGroupCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
