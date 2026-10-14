import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist ledger must pass. Check returns its problems, or none.
    protocol WorklistLedgerRule {
        func check(_ item: WorklistLedger) -> [String]
    }

    final class WorklistLedgerRequiredCodeRule: WorklistLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistLedgerUpdatedAtRangeRule: WorklistLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistLedger) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistLedgerGraceDaysRangeRule: WorklistLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistLedger) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistLedgerMarginRangeRule: WorklistLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistLedger) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistLedgerRequiredNameRule: WorklistLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a worklist ledger.
    final class WorklistLedgerValidator {
        var rules: [any WorklistLedgerRule]

        init(rules: [any WorklistLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistLedger]) -> [String: [String]] {
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

    static func defaultWorklistLedgerValidator() -> WorklistLedgerValidator {
        return WorklistLedgerValidator(
            rules: [
                WorklistLedgerRequiredCodeRule(message: "worklist ledger needs an entry"),
                WorklistLedgerUpdatedAtRangeRule(min: 3600, max: 86400),
                WorklistLedgerGraceDaysRangeRule(min: 16, max: 86400),
                WorklistLedgerMarginRangeRule(min: 7.5, max: 3930.1),
                WorklistLedgerRequiredNameRule(message: "worklist ledger needs this field"),
            ]
        )
    }
}
