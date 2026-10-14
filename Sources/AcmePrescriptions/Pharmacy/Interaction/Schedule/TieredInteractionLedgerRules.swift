import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered interaction ledger must pass. Check returns its problems, or none.
    protocol TieredInteractionLedgerRule {
        func check(_ item: TieredInteractionLedger) -> [String]
    }

    final class TieredInteractionLedgerCodePrefixRule: TieredInteractionLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredInteractionLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredInteractionLedgerRequiredCodeRule: TieredInteractionLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredInteractionLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredInteractionLedgerRequiredLabelRule: TieredInteractionLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredInteractionLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredInteractionLedgerMarginRangeRule: TieredInteractionLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredInteractionLedger) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredInteractionLedgerPayerLengthRule: TieredInteractionLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredInteractionLedger) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered interaction ledger.
    final class TieredInteractionLedgerValidator {
        var rules: [any TieredInteractionLedgerRule]

        init(rules: [any TieredInteractionLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredInteractionLedger) -> [String] {
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

        func requireValid(_ item: TieredInteractionLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredInteractionLedger]) -> [String: [String]] {
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

    static func defaultTieredInteractionLedgerValidator() -> TieredInteractionLedgerValidator {
        return TieredInteractionLedgerValidator(
            rules: [
                TieredInteractionLedgerCodePrefixRule(prefix: "REF"),
                TieredInteractionLedgerRequiredCodeRule(message: "tiered interaction ledger needs an entry"),
                TieredInteractionLedgerRequiredLabelRule(message: "tiered interaction ledger needs an entry"),
                TieredInteractionLedgerMarginRangeRule(min: 3.7, max: 4409.3),
                TieredInteractionLedgerPayerLengthRule(maxLength: 255),
            ]
        )
    }
}
