import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered handoff ledger must pass. Check returns its problems, or none.
    protocol TieredHandoffLedgerRule {
        func check(_ item: TieredHandoffLedger) -> [String]
    }

    final class TieredHandoffLedgerRequiredCodeRule: TieredHandoffLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredHandoffLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredHandoffLedgerRequiredChecksumRule: TieredHandoffLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredHandoffLedger) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredHandoffLedgerRequiredPhoneRule: TieredHandoffLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredHandoffLedger) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredHandoffLedgerChecksumLengthRule: TieredHandoffLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredHandoffLedger) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered handoff ledger.
    final class TieredHandoffLedgerValidator {
        var rules: [any TieredHandoffLedgerRule]

        init(rules: [any TieredHandoffLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredHandoffLedger) -> [String] {
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

        func requireValid(_ item: TieredHandoffLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredHandoffLedger]) -> [String: [String]] {
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

    static func defaultTieredHandoffLedgerValidator() -> TieredHandoffLedgerValidator {
        return TieredHandoffLedgerValidator(
            rules: [
                TieredHandoffLedgerRequiredCodeRule(message: "tiered handoff ledger needs an entry"),
                TieredHandoffLedgerRequiredChecksumRule(message: "tiered handoff ledger needs this field"),
                TieredHandoffLedgerRequiredPhoneRule(message: "tiered handoff ledger needs a value"),
                TieredHandoffLedgerChecksumLengthRule(maxLength: 64),
            ]
        )
    }
}
