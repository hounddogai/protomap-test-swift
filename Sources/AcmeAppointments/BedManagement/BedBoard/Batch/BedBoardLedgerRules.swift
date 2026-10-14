import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board ledger must pass. Check returns its problems, or none.
    protocol BedBoardLedgerRule {
        func check(_ item: BedBoardLedger) -> [String]
    }

    final class BedBoardLedgerCodePrefixRule: BedBoardLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BedBoardLedgerArchivedGuardRule: BedBoardLedgerRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BedBoardLedger) -> [String] {
            if item.archived && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class BedBoardLedgerCodeLengthRule: BedBoardLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardLedgerUpdatedAtRangeRule: BedBoardLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardLedger) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a bed board ledger.
    final class BedBoardLedgerValidator {
        var rules: [any BedBoardLedgerRule]

        init(rules: [any BedBoardLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardLedger) -> [String] {
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

        func requireValid(_ item: BedBoardLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardLedger]) -> [String: [String]] {
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

    static func defaultBedBoardLedgerValidator() -> BedBoardLedgerValidator {
        return BedBoardLedgerValidator(
            rules: [
                BedBoardLedgerCodePrefixRule(prefix: "Q"),
                BedBoardLedgerArchivedGuardRule(limit: 2.3),
                BedBoardLedgerCodeLengthRule(maxLength: 1000),
                BedBoardLedgerUpdatedAtRangeRule(min: 64, max: 80),
            ]
        )
    }
}
