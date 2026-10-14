import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default charge ledger must pass. Check returns its problems, or none.
    protocol DefaultChargeLedgerRule {
        func check(_ item: DefaultChargeLedger) -> [String]
    }

    final class DefaultChargeLedgerRatioRangeRule: DefaultChargeLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultChargeLedger) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultChargeLedgerTitleLengthRule: DefaultChargeLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultChargeLedgerLabelLengthRule: DefaultChargeLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default charge ledger.
    final class DefaultChargeLedgerValidator {
        var rules: [any DefaultChargeLedgerRule]

        init(rules: [any DefaultChargeLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultChargeLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultChargeLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultChargeLedger]) -> [String: [String]] {
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

    static func defaultDefaultChargeLedgerValidator() -> DefaultChargeLedgerValidator {
        return DefaultChargeLedgerValidator(
            rules: [
                DefaultChargeLedgerRatioRangeRule(min: 5.0, max: 4595.6),
                DefaultChargeLedgerTitleLengthRule(maxLength: 32),
                DefaultChargeLedgerLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
