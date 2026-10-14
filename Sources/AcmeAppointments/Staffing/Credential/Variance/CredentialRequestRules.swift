import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential request must pass. Check returns its problems, or none.
    protocol CredentialRequestRule {
        func check(_ item: CredentialRequest) -> [String]
    }

    final class CredentialRequestTitleLengthRule: CredentialRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialRequestCodePrefixRule: CredentialRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialRequestRequiredTitleRule: CredentialRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialRequestRequiredDiagnosisCodeRule: CredentialRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialRequest) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential request.
    final class CredentialRequestValidator {
        var rules: [any CredentialRequestRule]

        init(rules: [any CredentialRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialRequest) -> [String] {
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

        func requireValid(_ item: CredentialRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialRequest]) -> [String: [String]] {
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

    static func defaultCredentialRequestValidator() -> CredentialRequestValidator {
        return CredentialRequestValidator(
            rules: [
                CredentialRequestTitleLengthRule(maxLength: 1000),
                CredentialRequestCodePrefixRule(prefix: "ACM"),
                CredentialRequestRequiredTitleRule(message: "credential request needs this field"),
                CredentialRequestRequiredDiagnosisCodeRule(message: "credential request needs this field"),
            ]
        )
    }
}
