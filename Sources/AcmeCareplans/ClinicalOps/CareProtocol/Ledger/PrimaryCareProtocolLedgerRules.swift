import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary care protocol ledger must pass. Check returns its problems, or none.
    protocol PrimaryCareProtocolLedgerRule {
        func check(_ item: PrimaryCareProtocolLedger) -> [String]
    }

    final class PrimaryCareProtocolLedgerCodeLengthRule: PrimaryCareProtocolLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCareProtocolLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCareProtocolLedgerCodePrefixRule: PrimaryCareProtocolLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryCareProtocolLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryCareProtocolLedgerRequiredReviewerRule: PrimaryCareProtocolLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCareProtocolLedger) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCareProtocolLedgerRequiredCodeRule: PrimaryCareProtocolLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCareProtocolLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCareProtocolLedgerReviewerLengthRule: PrimaryCareProtocolLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCareProtocolLedger) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary care protocol ledger.
    final class PrimaryCareProtocolLedgerValidator {
        var rules: [any PrimaryCareProtocolLedgerRule]

        init(rules: [any PrimaryCareProtocolLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCareProtocolLedger) -> [String] {
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

        func requireValid(_ item: PrimaryCareProtocolLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCareProtocolLedger]) -> [String: [String]] {
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

    static func defaultPrimaryCareProtocolLedgerValidator() -> PrimaryCareProtocolLedgerValidator {
        return PrimaryCareProtocolLedgerValidator(
            rules: [
                PrimaryCareProtocolLedgerCodeLengthRule(maxLength: 80),
                PrimaryCareProtocolLedgerCodePrefixRule(prefix: "X"),
                PrimaryCareProtocolLedgerRequiredReviewerRule(
                    message: "primary care protocol ledger needs this field"
                ),
                PrimaryCareProtocolLedgerRequiredCodeRule(message: "primary care protocol ledger needs a value"),
                PrimaryCareProtocolLedgerReviewerLengthRule(maxLength: 255),
            ]
        )
    }
}
