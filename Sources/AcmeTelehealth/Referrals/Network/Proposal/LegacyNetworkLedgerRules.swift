import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy network ledger must pass. Check returns its problems, or none.
    protocol LegacyNetworkLedgerRule {
        func check(_ item: LegacyNetworkLedger) -> [String]
    }

    final class LegacyNetworkLedgerCodeLengthRule: LegacyNetworkLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyNetworkLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyNetworkLedgerEncounterIDLengthRule: LegacyNetworkLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyNetworkLedger) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyNetworkLedgerCodePrefixRule: LegacyNetworkLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyNetworkLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy network ledger.
    final class LegacyNetworkLedgerValidator {
        var rules: [any LegacyNetworkLedgerRule]

        init(rules: [any LegacyNetworkLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyNetworkLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyNetworkLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyNetworkLedger]) -> [String: [String]] {
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

    static func defaultLegacyNetworkLedgerValidator() -> LegacyNetworkLedgerValidator {
        return LegacyNetworkLedgerValidator(
            rules: [
                LegacyNetworkLedgerCodeLengthRule(maxLength: 32),
                LegacyNetworkLedgerEncounterIDLengthRule(maxLength: 64),
                LegacyNetworkLedgerCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
