import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff ledger must pass. Check returns its problems, or none.
    protocol HandoffLedgerRule {
        func check(_ item: HandoffLedger) -> [String]
    }

    final class HandoffLedgerRequiredCodeRule: HandoffLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffLedgerTitleLengthRule: HandoffLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffLedgerCodePrefixRule: HandoffLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffLedgerCodeLengthRule: HandoffLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff ledger.
    final class HandoffLedgerValidator {
        var rules: [any HandoffLedgerRule]

        init(rules: [any HandoffLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffLedger]) -> [String: [String]] {
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

    static func defaultHandoffLedgerValidator() -> HandoffLedgerValidator {
        return HandoffLedgerValidator(
            rules: [
                HandoffLedgerRequiredCodeRule(message: "handoff ledger needs a value"),
                HandoffLedgerTitleLengthRule(maxLength: 1000),
                HandoffLedgerCodePrefixRule(prefix: "Q"),
                HandoffLedgerCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
