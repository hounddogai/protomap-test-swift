import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered care protocol ledger must pass. Check returns its problems, or none.
    protocol TieredCareProtocolLedgerRule {
        func check(_ item: TieredCareProtocolLedger) -> [String]
    }

    final class TieredCareProtocolLedgerAcuityRangeRule: TieredCareProtocolLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareProtocolLedger) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredCareProtocolLedgerCodePrefixRule: TieredCareProtocolLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredCareProtocolLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredCareProtocolLedgerRequiredCodeRule: TieredCareProtocolLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareProtocolLedgerRequiredEncounterIDRule: TieredCareProtocolLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolLedger) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareProtocolLedgerRequiredReviewerRule: TieredCareProtocolLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolLedger) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care protocol ledger.
    final class TieredCareProtocolLedgerValidator {
        var rules: [any TieredCareProtocolLedgerRule]

        init(rules: [any TieredCareProtocolLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareProtocolLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCareProtocolLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareProtocolLedger]) -> [String: [String]] {
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

    static func defaultTieredCareProtocolLedgerValidator() -> TieredCareProtocolLedgerValidator {
        return TieredCareProtocolLedgerValidator(
            rules: [
                TieredCareProtocolLedgerAcuityRangeRule(min: 120, max: 3600),
                TieredCareProtocolLedgerCodePrefixRule(prefix: "X"),
                TieredCareProtocolLedgerRequiredCodeRule(message: "tiered care protocol ledger needs an entry"),
                TieredCareProtocolLedgerRequiredEncounterIDRule(message: "tiered care protocol ledger needs an entry"),
                TieredCareProtocolLedgerRequiredReviewerRule(message: "tiered care protocol ledger needs an entry"),
            ]
        )
    }
}
