import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional closure ledger must pass. Check returns its problems, or none.
    protocol RegionalClosureLedgerRule {
        func check(_ item: RegionalClosureLedger) -> [String]
    }

    final class RegionalClosureLedgerCapacityRangeRule: RegionalClosureLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalClosureLedger) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalClosureLedgerCostRangeRule: RegionalClosureLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalClosureLedger) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalClosureLedgerRequiredCodeRule: RegionalClosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClosureLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalClosureLedgerRequiredSummaryRule: RegionalClosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClosureLedger) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalClosureLedgerCodePrefixRule: RegionalClosureLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalClosureLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional closure ledger.
    final class RegionalClosureLedgerValidator {
        var rules: [any RegionalClosureLedgerRule]

        init(rules: [any RegionalClosureLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalClosureLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalClosureLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalClosureLedger]) -> [String: [String]] {
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

    static func defaultRegionalClosureLedgerValidator() -> RegionalClosureLedgerValidator {
        return RegionalClosureLedgerValidator(
            rules: [
                RegionalClosureLedgerCapacityRangeRule(min: 16, max: 32),
                RegionalClosureLedgerCostRangeRule(min: 8.1, max: 1293.1),
                RegionalClosureLedgerRequiredCodeRule(message: "regional closure ledger needs this field"),
                RegionalClosureLedgerRequiredSummaryRule(message: "regional closure ledger needs an entry"),
                RegionalClosureLedgerCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
