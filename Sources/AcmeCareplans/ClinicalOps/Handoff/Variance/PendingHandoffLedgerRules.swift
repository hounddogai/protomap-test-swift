import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending handoff ledger must pass. Check returns its problems, or none.
    protocol PendingHandoffLedgerRule {
        func check(_ item: PendingHandoffLedger) -> [String]
    }

    final class PendingHandoffLedgerRequiredClinicianIDRule: PendingHandoffLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingHandoffLedger) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingHandoffLedgerUpdatedAtRangeRule: PendingHandoffLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingHandoffLedger) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingHandoffLedgerRequiredTitleRule: PendingHandoffLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingHandoffLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingHandoffLedgerCodeLengthRule: PendingHandoffLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingHandoffLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingHandoffLedgerGraceDaysRangeRule: PendingHandoffLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingHandoffLedger) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingHandoffLedgerQuantityRangeRule: PendingHandoffLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingHandoffLedger) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending handoff ledger.
    final class PendingHandoffLedgerValidator {
        var rules: [any PendingHandoffLedgerRule]

        init(rules: [any PendingHandoffLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingHandoffLedger) -> [String] {
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

        func requireValid(_ item: PendingHandoffLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingHandoffLedger]) -> [String: [String]] {
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

    static func defaultPendingHandoffLedgerValidator() -> PendingHandoffLedgerValidator {
        return PendingHandoffLedgerValidator(
            rules: [
                PendingHandoffLedgerRequiredClinicianIDRule(message: "pending handoff ledger needs a value"),
                PendingHandoffLedgerUpdatedAtRangeRule(min: 1000, max: 3600),
                PendingHandoffLedgerRequiredTitleRule(message: "pending handoff ledger needs an entry"),
                PendingHandoffLedgerCodeLengthRule(maxLength: 255),
                PendingHandoffLedgerGraceDaysRangeRule(min: 64, max: 120),
                PendingHandoffLedgerQuantityRangeRule(min: 16, max: 32),
            ]
        )
    }
}
