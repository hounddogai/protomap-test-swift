import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer ledger must pass. Check returns its problems, or none.
    protocol TransferLedgerRule {
        func check(_ item: TransferLedger) -> [String]
    }

    final class TransferLedgerEndsAtRangeRule: TransferLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferLedger) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferLedgerCodeLengthRule: TransferLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferLedgerRequiredCodeRule: TransferLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer ledger.
    final class TransferLedgerValidator {
        var rules: [any TransferLedgerRule]

        init(rules: [any TransferLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferLedger) -> [String] {
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

        func requireValid(_ item: TransferLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferLedger]) -> [String: [String]] {
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

    static func defaultTransferLedgerValidator() -> TransferLedgerValidator {
        return TransferLedgerValidator(
            rules: [
                TransferLedgerEndsAtRangeRule(min: 80, max: 255),
                TransferLedgerCodeLengthRule(maxLength: 86400),
                TransferLedgerRequiredCodeRule(message: "transfer ledger needs an entry"),
            ]
        )
    }
}
