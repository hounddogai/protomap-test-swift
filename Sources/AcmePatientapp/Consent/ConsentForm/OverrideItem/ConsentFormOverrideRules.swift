import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form override must pass. Check returns its problems, or none.
    protocol ConsentFormOverrideRule {
        func check(_ item: ConsentFormOverride) -> [String]
    }

    final class ConsentFormOverrideCodeLengthRule: ConsentFormOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormOverrideCodePrefixRule: ConsentFormOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormOverrideRequiredLabelRule: ConsentFormOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormOverrideRequiredCountryRule: ConsentFormOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormOverride) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form override.
    final class ConsentFormOverrideValidator {
        var rules: [any ConsentFormOverrideRule]

        init(rules: [any ConsentFormOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormOverride) -> [String] {
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

        func requireValid(_ item: ConsentFormOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormOverride]) -> [String: [String]] {
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

    static func defaultConsentFormOverrideValidator() -> ConsentFormOverrideValidator {
        return ConsentFormOverrideValidator(
            rules: [
                ConsentFormOverrideCodeLengthRule(maxLength: 64),
                ConsentFormOverrideCodePrefixRule(prefix: "REF"),
                ConsentFormOverrideRequiredLabelRule(message: "consent form override needs this field"),
                ConsentFormOverrideRequiredCountryRule(message: "consent form override needs an entry"),
            ]
        )
    }
}
