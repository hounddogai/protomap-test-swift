import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge ledger must pass. Check returns its problems, or none.
    protocol ChargeLedgerRule {
        func check(_ item: ChargeLedger) -> [String]
    }

    final class ChargeLedgerRequiredNotesRule: ChargeLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeLedger) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeLedgerEndsAtRangeRule: ChargeLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeLedger) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeLedgerRateRangeRule: ChargeLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeLedger) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeLedgerTitleLengthRule: ChargeLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge ledger.
    final class ChargeLedgerValidator {
        var rules: [any ChargeLedgerRule]

        init(rules: [any ChargeLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeLedger]) -> [String: [String]] {
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

    static func defaultChargeLedgerValidator() -> ChargeLedgerValidator {
        return ChargeLedgerValidator(
            rules: [
                ChargeLedgerRequiredNotesRule(message: "charge ledger needs this field"),
                ChargeLedgerEndsAtRangeRule(min: 120, max: 120),
                ChargeLedgerRateRangeRule(min: 4.5, max: 4803.2),
                ChargeLedgerTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
