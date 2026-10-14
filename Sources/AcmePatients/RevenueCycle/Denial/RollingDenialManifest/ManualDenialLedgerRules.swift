import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual denial ledger must pass. Check returns its problems, or none.
    protocol ManualDenialLedgerRule {
        func check(_ item: ManualDenialLedger) -> [String]
    }

    final class ManualDenialLedgerRequiredFacilityRule: ManualDenialLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDenialLedger) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDenialLedgerNameLengthRule: ManualDenialLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDenialLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDenialLedgerCodePrefixRule: ManualDenialLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualDenialLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualDenialLedgerFacilityLengthRule: ManualDenialLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDenialLedger) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual denial ledger.
    final class ManualDenialLedgerValidator {
        var rules: [any ManualDenialLedgerRule]

        init(rules: [any ManualDenialLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDenialLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualDenialLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDenialLedger]) -> [String: [String]] {
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

    static func defaultManualDenialLedgerValidator() -> ManualDenialLedgerValidator {
        return ManualDenialLedgerValidator(
            rules: [
                ManualDenialLedgerRequiredFacilityRule(message: "manual denial ledger needs this field"),
                ManualDenialLedgerNameLengthRule(maxLength: 32),
                ManualDenialLedgerCodePrefixRule(prefix: "REF"),
                ManualDenialLedgerFacilityLengthRule(maxLength: 1000),
            ]
        )
    }
}
