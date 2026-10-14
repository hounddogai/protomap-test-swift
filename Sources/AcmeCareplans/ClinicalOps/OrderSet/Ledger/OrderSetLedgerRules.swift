import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set ledger must pass. Check returns its problems, or none.
    protocol OrderSetLedgerRule {
        func check(_ item: OrderSetLedger) -> [String]
    }

    final class OrderSetLedgerRequiredNameRule: OrderSetLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetLedgerScoreRangeRule: OrderSetLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetLedger) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetLedgerRequiredCodeRule: OrderSetLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetLedgerCodeLengthRule: OrderSetLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set ledger.
    final class OrderSetLedgerValidator {
        var rules: [any OrderSetLedgerRule]

        init(rules: [any OrderSetLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetLedger]) -> [String: [String]] {
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

    static func defaultOrderSetLedgerValidator() -> OrderSetLedgerValidator {
        return OrderSetLedgerValidator(
            rules: [
                OrderSetLedgerRequiredNameRule(message: "order set ledger needs a value"),
                OrderSetLedgerScoreRangeRule(min: 5.0, max: 1691.7),
                OrderSetLedgerRequiredCodeRule(message: "order set ledger needs this field"),
                OrderSetLedgerCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
