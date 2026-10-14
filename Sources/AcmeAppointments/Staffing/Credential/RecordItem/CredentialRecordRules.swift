import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential record must pass. Check returns its problems, or none.
    protocol CredentialRecordRule {
        func check(_ item: CredentialRecord) -> [String]
    }

    final class CredentialRecordCodeLengthRule: CredentialRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialRecordRequiredCodeRule: CredentialRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialRecordCodePrefixRule: CredentialRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential record.
    final class CredentialRecordValidator {
        var rules: [any CredentialRecordRule]

        init(rules: [any CredentialRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialRecord) -> [String] {
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

        func requireValid(_ item: CredentialRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialRecord]) -> [String: [String]] {
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

    static func defaultCredentialRecordValidator() -> CredentialRecordValidator {
        return CredentialRecordValidator(
            rules: [
                CredentialRecordCodeLengthRule(maxLength: 120),
                CredentialRecordRequiredCodeRule(message: "credential record needs an entry"),
                CredentialRecordCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
