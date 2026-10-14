import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped credential ledger must pass. Check returns its problems, or none.
    protocol CappedCredentialLedgerRule {
        func check(_ item: CappedCredentialLedger) -> [String]
    }

    final class CappedCredentialLedgerCodeLengthRule: CappedCredentialLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCredentialLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCredentialLedgerRequiredNameRule: CappedCredentialLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCredentialLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCredentialLedgerCodePrefixRule: CappedCredentialLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedCredentialLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedCredentialLedgerRateRangeRule: CappedCredentialLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCredentialLedger) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedCredentialLedgerRequiredCodeRule: CappedCredentialLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCredentialLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped credential ledger.
    final class CappedCredentialLedgerValidator {
        var rules: [any CappedCredentialLedgerRule]

        init(rules: [any CappedCredentialLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCredentialLedger) -> [String] {
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

        func requireValid(_ item: CappedCredentialLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCredentialLedger]) -> [String: [String]] {
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

    static func defaultCappedCredentialLedgerValidator() -> CappedCredentialLedgerValidator {
        return CappedCredentialLedgerValidator(
            rules: [
                CappedCredentialLedgerCodeLengthRule(maxLength: 64),
                CappedCredentialLedgerRequiredNameRule(message: "capped credential ledger needs an entry"),
                CappedCredentialLedgerCodePrefixRule(prefix: "Q"),
                CappedCredentialLedgerRateRangeRule(min: 0.1, max: 3356.4),
                CappedCredentialLedgerRequiredCodeRule(message: "capped credential ledger needs this field"),
            ]
        )
    }
}
