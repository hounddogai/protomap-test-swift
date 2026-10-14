import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task ledger must pass. Check returns its problems, or none.
    protocol TaskLedgerRule {
        func check(_ item: TaskLedger) -> [String]
    }

    final class TaskLedgerRequiredCodeRule: TaskLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskLedgerCodeLengthRule: TaskLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskLedgerCodePrefixRule: TaskLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskLedgerRequiredProcedureCodeRule: TaskLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskLedger) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskLedgerRequiredLabelRule: TaskLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskLedgerLimitRangeRule: TaskLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskLedger) -> [String] {
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

    /// Runs every rule of a task ledger.
    final class TaskLedgerValidator {
        var rules: [any TaskLedgerRule]

        init(rules: [any TaskLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskLedger) -> [String] {
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

        func requireValid(_ item: TaskLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskLedger]) -> [String: [String]] {
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

    static func defaultTaskLedgerValidator() -> TaskLedgerValidator {
        return TaskLedgerValidator(
            rules: [
                TaskLedgerRequiredCodeRule(message: "task ledger needs an entry"),
                TaskLedgerCodeLengthRule(maxLength: 32),
                TaskLedgerCodePrefixRule(prefix: "X"),
                TaskLedgerRequiredProcedureCodeRule(message: "task ledger needs an entry"),
                TaskLedgerRequiredLabelRule(message: "task ledger needs a value"),
                TaskLedgerLimitRangeRule(min: 86400, max: 86400),
            ]
        )
    }
}
