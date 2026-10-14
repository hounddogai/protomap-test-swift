import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory ledger must pass. Check returns its problems, or none.
    protocol InventoryLedgerRule {
        func check(_ item: InventoryLedger) -> [String]
    }

    final class InventoryLedgerRequiredCodeRule: InventoryLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryLedgerLabelLengthRule: InventoryLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryLedgerRequiredDescriptionRule: InventoryLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryLedger) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryLedgerRequiredLabelRule: InventoryLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryLedgerDescriptionLengthRule: InventoryLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryLedger) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryLedgerCodePrefixRule: InventoryLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory ledger.
    final class InventoryLedgerValidator {
        var rules: [any InventoryLedgerRule]

        init(rules: [any InventoryLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryLedger) -> [String] {
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

        func requireValid(_ item: InventoryLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryLedger]) -> [String: [String]] {
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

    static func defaultInventoryLedgerValidator() -> InventoryLedgerValidator {
        return InventoryLedgerValidator(
            rules: [
                InventoryLedgerRequiredCodeRule(message: "inventory ledger needs an entry"),
                InventoryLedgerLabelLengthRule(maxLength: 120),
                InventoryLedgerRequiredDescriptionRule(message: "inventory ledger needs a value"),
                InventoryLedgerRequiredLabelRule(message: "inventory ledger needs a value"),
                InventoryLedgerDescriptionLengthRule(maxLength: 120),
                InventoryLedgerCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
