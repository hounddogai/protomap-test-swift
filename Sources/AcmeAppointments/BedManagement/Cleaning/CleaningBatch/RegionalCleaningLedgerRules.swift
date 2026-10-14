import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional cleaning ledger must pass. Check returns its problems, or none.
    protocol RegionalCleaningLedgerRule {
        func check(_ item: RegionalCleaningLedger) -> [String]
    }

    final class RegionalCleaningLedgerAllowedNameRule: RegionalCleaningLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalCleaningLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class RegionalCleaningLedgerCodePrefixRule: RegionalCleaningLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalCleaningLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalCleaningLedgerCodeLengthRule: RegionalCleaningLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCleaningLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional cleaning ledger.
    final class RegionalCleaningLedgerValidator {
        var rules: [any RegionalCleaningLedgerRule]

        init(rules: [any RegionalCleaningLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCleaningLedger) -> [String] {
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

        func requireValid(_ item: RegionalCleaningLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCleaningLedger]) -> [String: [String]] {
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

    static func defaultRegionalCleaningLedgerValidator() -> RegionalCleaningLedgerValidator {
        return RegionalCleaningLedgerValidator(
            rules: [
                RegionalCleaningLedgerAllowedNameRule(allowed: []),
                RegionalCleaningLedgerCodePrefixRule(prefix: "Q"),
                RegionalCleaningLedgerCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
