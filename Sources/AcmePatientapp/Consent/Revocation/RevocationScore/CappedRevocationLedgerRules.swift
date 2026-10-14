import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped revocation ledger must pass. Check returns its problems, or none.
    protocol CappedRevocationLedgerRule {
        func check(_ item: CappedRevocationLedger) -> [String]
    }

    final class CappedRevocationLedgerCodePrefixRule: CappedRevocationLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRevocationLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedRevocationLedgerRequiredCodeRule: CappedRevocationLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRevocationLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRevocationLedgerCodeLengthRule: CappedRevocationLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRevocationLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRevocationLedgerRequiredPatientRefRule: CappedRevocationLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRevocationLedger) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRevocationLedgerRequiredNameRule: CappedRevocationLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRevocationLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped revocation ledger.
    final class CappedRevocationLedgerValidator {
        var rules: [any CappedRevocationLedgerRule]

        init(rules: [any CappedRevocationLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRevocationLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedRevocationLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRevocationLedger]) -> [String: [String]] {
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

    static func defaultCappedRevocationLedgerValidator() -> CappedRevocationLedgerValidator {
        return CappedRevocationLedgerValidator(
            rules: [
                CappedRevocationLedgerCodePrefixRule(prefix: "REF"),
                CappedRevocationLedgerRequiredCodeRule(message: "capped revocation ledger needs a value"),
                CappedRevocationLedgerCodeLengthRule(maxLength: 80),
                CappedRevocationLedgerRequiredPatientRefRule(message: "capped revocation ledger needs a value"),
                CappedRevocationLedgerRequiredNameRule(message: "capped revocation ledger needs an entry"),
            ]
        )
    }
}
