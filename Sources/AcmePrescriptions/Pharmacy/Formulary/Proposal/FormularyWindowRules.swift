import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary window must pass. Check returns its problems, or none.
    protocol FormularyWindowRule {
        func check(_ item: FormularyWindow) -> [String]
    }

    final class FormularyWindowRequiredCodeRule: FormularyWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyWindowRequiredOwnerIDRule: FormularyWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyWindow) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyWindowCodePrefixRule: FormularyWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FormularyWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FormularyWindowChannelLengthRule: FormularyWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyWindow) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary window.
    final class FormularyWindowValidator {
        var rules: [any FormularyWindowRule]

        init(rules: [any FormularyWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyWindow) -> [String] {
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

        func requireValid(_ item: FormularyWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyWindow]) -> [String: [String]] {
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

    static func defaultFormularyWindowValidator() -> FormularyWindowValidator {
        return FormularyWindowValidator(
            rules: [
                FormularyWindowRequiredCodeRule(message: "formulary window needs a value"),
                FormularyWindowRequiredOwnerIDRule(message: "formulary window needs this field"),
                FormularyWindowCodePrefixRule(prefix: "ACM"),
                FormularyWindowChannelLengthRule(maxLength: 1000),
            ]
        )
    }
}
