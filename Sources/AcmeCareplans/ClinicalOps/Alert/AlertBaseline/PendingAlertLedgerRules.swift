import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending alert ledger must pass. Check returns its problems, or none.
    protocol PendingAlertLedgerRule {
        func check(_ item: PendingAlertLedger) -> [String]
    }

    final class PendingAlertLedgerRequiredTitleRule: PendingAlertLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAlertLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingAlertLedgerRequiredChecksumRule: PendingAlertLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAlertLedger) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingAlertLedgerPatientRefLengthRule: PendingAlertLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAlertLedger) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAlertLedgerRequiredCodeRule: PendingAlertLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAlertLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending alert ledger.
    final class PendingAlertLedgerValidator {
        var rules: [any PendingAlertLedgerRule]

        init(rules: [any PendingAlertLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAlertLedger) -> [String] {
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

        func requireValid(_ item: PendingAlertLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAlertLedger]) -> [String: [String]] {
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

    static func defaultPendingAlertLedgerValidator() -> PendingAlertLedgerValidator {
        return PendingAlertLedgerValidator(
            rules: [
                PendingAlertLedgerRequiredTitleRule(message: "pending alert ledger needs a value"),
                PendingAlertLedgerRequiredChecksumRule(message: "pending alert ledger needs a value"),
                PendingAlertLedgerPatientRefLengthRule(maxLength: 120),
                PendingAlertLedgerRequiredCodeRule(message: "pending alert ledger needs an entry"),
            ]
        )
    }
}
