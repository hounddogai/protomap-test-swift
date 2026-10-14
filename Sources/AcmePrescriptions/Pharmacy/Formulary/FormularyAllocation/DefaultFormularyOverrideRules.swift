import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default formulary override must pass. Check returns its problems, or none.
    protocol DefaultFormularyOverrideRule {
        func check(_ item: DefaultFormularyOverride) -> [String]
    }

    final class DefaultFormularyOverrideRequiredWardRule: DefaultFormularyOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFormularyOverride) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFormularyOverrideCodePrefixRule: DefaultFormularyOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultFormularyOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultFormularyOverrideRequiredCodeRule: DefaultFormularyOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFormularyOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default formulary override.
    final class DefaultFormularyOverrideValidator {
        var rules: [any DefaultFormularyOverrideRule]

        init(rules: [any DefaultFormularyOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultFormularyOverride) -> [String] {
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

        func requireValid(_ item: DefaultFormularyOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultFormularyOverride]) -> [String: [String]] {
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

    static func defaultDefaultFormularyOverrideValidator() -> DefaultFormularyOverrideValidator {
        return DefaultFormularyOverrideValidator(
            rules: [
                DefaultFormularyOverrideRequiredWardRule(message: "default formulary override needs this field"),
                DefaultFormularyOverrideCodePrefixRule(prefix: "Q"),
                DefaultFormularyOverrideRequiredCodeRule(message: "default formulary override needs this field"),
            ]
        )
    }
}
