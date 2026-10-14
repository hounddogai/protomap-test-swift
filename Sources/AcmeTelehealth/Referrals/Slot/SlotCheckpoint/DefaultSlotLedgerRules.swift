import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default slot ledger must pass. Check returns its problems, or none.
    protocol DefaultSlotLedgerRule {
        func check(_ item: DefaultSlotLedger) -> [String]
    }

    final class DefaultSlotLedgerCodePrefixRule: DefaultSlotLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultSlotLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultSlotLedgerVersionRangeRule: DefaultSlotLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSlotLedger) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultSlotLedgerRequiredCurrencyRule: DefaultSlotLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSlotLedger) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSlotLedgerGraceDaysRangeRule: DefaultSlotLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSlotLedger) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default slot ledger.
    final class DefaultSlotLedgerValidator {
        var rules: [any DefaultSlotLedgerRule]

        init(rules: [any DefaultSlotLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSlotLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultSlotLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSlotLedger]) -> [String: [String]] {
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

    static func defaultDefaultSlotLedgerValidator() -> DefaultSlotLedgerValidator {
        return DefaultSlotLedgerValidator(
            rules: [
                DefaultSlotLedgerCodePrefixRule(prefix: "X"),
                DefaultSlotLedgerVersionRangeRule(min: 120, max: 3600),
                DefaultSlotLedgerRequiredCurrencyRule(message: "default slot ledger needs an entry"),
                DefaultSlotLedgerGraceDaysRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
