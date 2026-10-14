import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped disclosure ledger must pass. Check returns its problems, or none.
    protocol CappedDisclosureLedgerRule {
        func check(_ item: CappedDisclosureLedger) -> [String]
    }

    final class CappedDisclosureLedgerUpdatedAtRangeRule: CappedDisclosureLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDisclosureLedger) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedDisclosureLedgerRequiredCodeRule: CappedDisclosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDisclosureLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDisclosureLedgerRegionLengthRule: CappedDisclosureLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedDisclosureLedger) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedDisclosureLedgerRequiredNotesRule: CappedDisclosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDisclosureLedger) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDisclosureLedgerBudgetRangeRule: CappedDisclosureLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDisclosureLedger) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedDisclosureLedgerCodePrefixRule: CappedDisclosureLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedDisclosureLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped disclosure ledger.
    final class CappedDisclosureLedgerValidator {
        var rules: [any CappedDisclosureLedgerRule]

        init(rules: [any CappedDisclosureLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDisclosureLedger) -> [String] {
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

        func requireValid(_ item: CappedDisclosureLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDisclosureLedger]) -> [String: [String]] {
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

    static func defaultCappedDisclosureLedgerValidator() -> CappedDisclosureLedgerValidator {
        return CappedDisclosureLedgerValidator(
            rules: [
                CappedDisclosureLedgerUpdatedAtRangeRule(min: 64, max: 255),
                CappedDisclosureLedgerRequiredCodeRule(message: "capped disclosure ledger needs this field"),
                CappedDisclosureLedgerRegionLengthRule(maxLength: 86400),
                CappedDisclosureLedgerRequiredNotesRule(message: "capped disclosure ledger needs this field"),
                CappedDisclosureLedgerBudgetRangeRule(min: 2.2, max: 699.6),
                CappedDisclosureLedgerCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
