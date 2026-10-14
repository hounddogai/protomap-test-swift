import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual census ledger must pass. Check returns its problems, or none.
    protocol ManualCensusLedgerRule {
        func check(_ item: ManualCensusLedger) -> [String]
    }

    final class ManualCensusLedgerAllowedCodeRule: ManualCensusLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualCensusLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class ManualCensusLedgerRequiredCodeRule: ManualCensusLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCensusLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCensusLedgerNameLengthRule: ManualCensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCensusLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCensusLedgerSummaryLengthRule: ManualCensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCensusLedger) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCensusLedgerRequiredSummaryRule: ManualCensusLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCensusLedger) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCensusLedgerCapacityRangeRule: ManualCensusLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCensusLedger) -> [String] {
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

    /// Runs every rule of a manual census ledger.
    final class ManualCensusLedgerValidator {
        var rules: [any ManualCensusLedgerRule]

        init(rules: [any ManualCensusLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCensusLedger) -> [String] {
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

        func requireValid(_ item: ManualCensusLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCensusLedger]) -> [String: [String]] {
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

    static func defaultManualCensusLedgerValidator() -> ManualCensusLedgerValidator {
        return ManualCensusLedgerValidator(
            rules: [
                ManualCensusLedgerAllowedCodeRule(allowed: ["primary", "tiered"]),
                ManualCensusLedgerRequiredCodeRule(message: "manual census ledger needs an entry"),
                ManualCensusLedgerNameLengthRule(maxLength: 1000),
                ManualCensusLedgerSummaryLengthRule(maxLength: 16),
                ManualCensusLedgerRequiredSummaryRule(message: "manual census ledger needs a value"),
                ManualCensusLedgerCapacityRangeRule(min: 16, max: 32),
            ]
        )
    }
}
