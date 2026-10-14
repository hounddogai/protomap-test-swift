import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read ledger must pass. Check returns its problems, or none.
    protocol ReadLedgerRule {
        func check(_ item: ReadLedger) -> [String]
    }

    final class ReadLedgerOwnerIDLengthRule: ReadLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadLedger) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadLedgerRequiredOwnerIDRule: ReadLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadLedger) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadLedgerTitleLengthRule: ReadLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadLedgerCodePrefixRule: ReadLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a read ledger.
    final class ReadLedgerValidator {
        var rules: [any ReadLedgerRule]

        init(rules: [any ReadLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadLedger) -> [String] {
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

        func requireValid(_ item: ReadLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadLedger]) -> [String: [String]] {
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

    static func defaultReadLedgerValidator() -> ReadLedgerValidator {
        return ReadLedgerValidator(
            rules: [
                ReadLedgerOwnerIDLengthRule(maxLength: 255),
                ReadLedgerRequiredOwnerIDRule(message: "read ledger needs this field"),
                ReadLedgerTitleLengthRule(maxLength: 80),
                ReadLedgerCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
