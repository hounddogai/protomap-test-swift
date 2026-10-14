import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive read ledger must pass. Check returns its problems, or none.
    protocol AdaptiveReadLedgerRule {
        func check(_ item: AdaptiveReadLedger) -> [String]
    }

    final class AdaptiveReadLedgerCodeLengthRule: AdaptiveReadLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReadLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveReadLedgerFacilityLengthRule: AdaptiveReadLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReadLedger) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveReadLedgerLabelLengthRule: AdaptiveReadLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReadLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveReadLedgerUpdatedAtRangeRule: AdaptiveReadLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveReadLedger) -> [String] {
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

    /// Runs every rule of a adaptive read ledger.
    final class AdaptiveReadLedgerValidator {
        var rules: [any AdaptiveReadLedgerRule]

        init(rules: [any AdaptiveReadLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveReadLedger) -> [String] {
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

        func requireValid(_ item: AdaptiveReadLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveReadLedger]) -> [String: [String]] {
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

    static func defaultAdaptiveReadLedgerValidator() -> AdaptiveReadLedgerValidator {
        return AdaptiveReadLedgerValidator(
            rules: [
                AdaptiveReadLedgerCodeLengthRule(maxLength: 32),
                AdaptiveReadLedgerFacilityLengthRule(maxLength: 16),
                AdaptiveReadLedgerLabelLengthRule(maxLength: 255),
                AdaptiveReadLedgerUpdatedAtRangeRule(min: 80, max: 120),
            ]
        )
    }
}
