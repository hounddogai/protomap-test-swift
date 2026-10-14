import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending census ledger must pass. Check returns its problems, or none.
    protocol PendingCensusLedgerRule {
        func check(_ item: PendingCensusLedger) -> [String]
    }

    final class PendingCensusLedgerMarginRangeRule: PendingCensusLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCensusLedger) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCensusLedgerCodeLengthRule: PendingCensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCensusLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCensusLedgerClinicianIDLengthRule: PendingCensusLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCensusLedger) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCensusLedgerWeightRangeRule: PendingCensusLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCensusLedger) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingCensusLedgerBudgetRangeRule: PendingCensusLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCensusLedger) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending census ledger.
    final class PendingCensusLedgerValidator {
        var rules: [any PendingCensusLedgerRule]

        init(rules: [any PendingCensusLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCensusLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCensusLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCensusLedger]) -> [String: [String]] {
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

    static func defaultPendingCensusLedgerValidator() -> PendingCensusLedgerValidator {
        return PendingCensusLedgerValidator(
            rules: [
                PendingCensusLedgerMarginRangeRule(min: 7.7, max: 2529.8),
                PendingCensusLedgerCodeLengthRule(maxLength: 86400),
                PendingCensusLedgerClinicianIDLengthRule(maxLength: 16),
                PendingCensusLedgerWeightRangeRule(min: 0.6, max: 787.3),
                PendingCensusLedgerBudgetRangeRule(min: 9.8, max: 4798.6),
            ]
        )
    }
}
