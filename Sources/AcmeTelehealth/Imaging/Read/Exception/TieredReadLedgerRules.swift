import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered read ledger must pass. Check returns its problems, or none.
    protocol TieredReadLedgerRule {
        func check(_ item: TieredReadLedger) -> [String]
    }

    final class TieredReadLedgerRequiredCodeRule: TieredReadLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadLedgerSourceLengthRule: TieredReadLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadLedger) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadLedgerAllowedCodeRule: TieredReadLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredReadLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class TieredReadLedgerCodePrefixRule: TieredReadLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredReadLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredReadLedgerCodeLengthRule: TieredReadLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadLedgerCopayRangeRule: TieredReadLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReadLedger) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered read ledger.
    final class TieredReadLedgerValidator {
        var rules: [any TieredReadLedgerRule]

        init(rules: [any TieredReadLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReadLedger) -> [String] {
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

        func requireValid(_ item: TieredReadLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReadLedger]) -> [String: [String]] {
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

    static func defaultTieredReadLedgerValidator() -> TieredReadLedgerValidator {
        return TieredReadLedgerValidator(
            rules: [
                TieredReadLedgerRequiredCodeRule(message: "tiered read ledger needs a value"),
                TieredReadLedgerSourceLengthRule(maxLength: 255),
                TieredReadLedgerAllowedCodeRule(allowed: []),
                TieredReadLedgerCodePrefixRule(prefix: "REF"),
                TieredReadLedgerCodeLengthRule(maxLength: 80),
                TieredReadLedgerCopayRangeRule(min: 6.7, max: 432.0),
            ]
        )
    }
}
