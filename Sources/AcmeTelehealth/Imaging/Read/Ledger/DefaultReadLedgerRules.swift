import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default read ledger must pass. Check returns its problems, or none.
    protocol DefaultReadLedgerRule {
        func check(_ item: DefaultReadLedger) -> [String]
    }

    final class DefaultReadLedgerLabelLengthRule: DefaultReadLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReadLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReadLedgerGraceDaysRangeRule: DefaultReadLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReadLedger) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultReadLedgerRegionLengthRule: DefaultReadLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReadLedger) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default read ledger.
    final class DefaultReadLedgerValidator {
        var rules: [any DefaultReadLedgerRule]

        init(rules: [any DefaultReadLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultReadLedger) -> [String] {
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

        func requireValid(_ item: DefaultReadLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultReadLedger]) -> [String: [String]] {
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

    static func defaultDefaultReadLedgerValidator() -> DefaultReadLedgerValidator {
        return DefaultReadLedgerValidator(
            rules: [
                DefaultReadLedgerLabelLengthRule(maxLength: 86400),
                DefaultReadLedgerGraceDaysRangeRule(min: 120, max: 86400),
                DefaultReadLedgerRegionLengthRule(maxLength: 120),
            ]
        )
    }
}
