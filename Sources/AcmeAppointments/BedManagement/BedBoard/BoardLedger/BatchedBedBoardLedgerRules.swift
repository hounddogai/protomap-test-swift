import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched bed board ledger must pass. Check returns its problems, or none.
    protocol BatchedBedBoardLedgerRule {
        func check(_ item: BatchedBedBoardLedger) -> [String]
    }

    final class BatchedBedBoardLedgerLimitRangeRule: BatchedBedBoardLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedBedBoardLedger) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedBedBoardLedgerAttemptsRangeRule: BatchedBedBoardLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedBedBoardLedger) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedBedBoardLedgerRequiredTitleRule: BatchedBedBoardLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedBedBoardLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedBedBoardLedgerPinnedGuardRule: BatchedBedBoardLedgerRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedBedBoardLedger) -> [String] {
            if item.pinned && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class BatchedBedBoardLedgerProcedureCodeLengthRule: BatchedBedBoardLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedBedBoardLedger) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched bed board ledger.
    final class BatchedBedBoardLedgerValidator {
        var rules: [any BatchedBedBoardLedgerRule]

        init(rules: [any BatchedBedBoardLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedBedBoardLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedBedBoardLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedBedBoardLedger]) -> [String: [String]] {
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

    static func defaultBatchedBedBoardLedgerValidator() -> BatchedBedBoardLedgerValidator {
        return BatchedBedBoardLedgerValidator(
            rules: [
                BatchedBedBoardLedgerLimitRangeRule(min: 32, max: 64),
                BatchedBedBoardLedgerAttemptsRangeRule(min: 32, max: 86400),
                BatchedBedBoardLedgerRequiredTitleRule(message: "batched bed board ledger needs a value"),
                BatchedBedBoardLedgerPinnedGuardRule(limit: 16),
                BatchedBedBoardLedgerProcedureCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
