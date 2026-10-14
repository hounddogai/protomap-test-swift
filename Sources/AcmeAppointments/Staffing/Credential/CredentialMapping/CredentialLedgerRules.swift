import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential ledger must pass. Check returns its problems, or none.
    protocol CredentialLedgerRule {
        func check(_ item: CredentialLedger) -> [String]
    }

    final class CredentialLedgerChecksumLengthRule: CredentialLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialLedger) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialLedgerCodePrefixRule: CredentialLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialLedgerRequiredTitleRule: CredentialLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialLedgerAllowedCodeRule: CredentialLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class CredentialLedgerActiveGuardRule: CredentialLedgerRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CredentialLedger) -> [String] {
            if item.active && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a credential ledger.
    final class CredentialLedgerValidator {
        var rules: [any CredentialLedgerRule]

        init(rules: [any CredentialLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialLedger) -> [String] {
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

        func requireValid(_ item: CredentialLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialLedger]) -> [String: [String]] {
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

    static func defaultCredentialLedgerValidator() -> CredentialLedgerValidator {
        return CredentialLedgerValidator(
            rules: [
                CredentialLedgerChecksumLengthRule(maxLength: 3600),
                CredentialLedgerCodePrefixRule(prefix: "REF"),
                CredentialLedgerRequiredTitleRule(message: "credential ledger needs an entry"),
                CredentialLedgerAllowedCodeRule(allowed: []),
                CredentialLedgerActiveGuardRule(limit: 5.3),
            ]
        )
    }
}
