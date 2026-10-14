import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential draft must pass. Check returns its problems, or none.
    protocol CredentialDraftRule {
        func check(_ item: CredentialDraft) -> [String]
    }

    final class CredentialDraftTitleLengthRule: CredentialDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialDraftRequiredCodeRule: CredentialDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialDraftCodePrefixRule: CredentialDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialDraftPayerLengthRule: CredentialDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialDraft) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential draft.
    final class CredentialDraftValidator {
        var rules: [any CredentialDraftRule]

        init(rules: [any CredentialDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialDraft]) -> [String: [String]] {
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

    static func defaultCredentialDraftValidator() -> CredentialDraftValidator {
        return CredentialDraftValidator(
            rules: [
                CredentialDraftTitleLengthRule(maxLength: 64),
                CredentialDraftRequiredCodeRule(message: "credential draft needs a value"),
                CredentialDraftCodePrefixRule(prefix: "REF"),
                CredentialDraftPayerLengthRule(maxLength: 3600),
            ]
        )
    }
}
