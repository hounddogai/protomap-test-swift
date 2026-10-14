import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation entry must pass. Check returns its problems, or none.
    protocol RevocationEntryRule {
        func check(_ item: RevocationEntry) -> [String]
    }

    final class RevocationEntryPatientRefLengthRule: RevocationEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationEntry) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationEntryRequiredLocaleRule: RevocationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationEntry) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationEntryLocaleLengthRule: RevocationEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationEntry) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationEntryRequiredCodeRule: RevocationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation entry.
    final class RevocationEntryValidator {
        var rules: [any RevocationEntryRule]

        init(rules: [any RevocationEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationEntry) -> [String] {
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

        func requireValid(_ item: RevocationEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationEntry]) -> [String: [String]] {
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

    static func defaultRevocationEntryValidator() -> RevocationEntryValidator {
        return RevocationEntryValidator(
            rules: [
                RevocationEntryPatientRefLengthRule(maxLength: 3600),
                RevocationEntryRequiredLocaleRule(message: "revocation entry needs a value"),
                RevocationEntryLocaleLengthRule(maxLength: 32),
                RevocationEntryRequiredCodeRule(message: "revocation entry needs this field"),
            ]
        )
    }
}
