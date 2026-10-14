import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot ledger must pass. Check returns its problems, or none.
    protocol SlotLedgerRule {
        func check(_ item: SlotLedger) -> [String]
    }

    final class SlotLedgerBatchSizeRangeRule: SlotLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotLedger) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotLedgerPinnedGuardRule: SlotLedgerRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SlotLedger) -> [String] {
            if item.pinned && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class SlotLedgerCodePrefixRule: SlotLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotLedgerFloorValueRangeRule: SlotLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotLedger) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotLedgerRequiredPatientRefRule: SlotLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotLedger) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot ledger.
    final class SlotLedgerValidator {
        var rules: [any SlotLedgerRule]

        init(rules: [any SlotLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotLedger]) -> [String: [String]] {
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

    static func defaultSlotLedgerValidator() -> SlotLedgerValidator {
        return SlotLedgerValidator(
            rules: [
                SlotLedgerBatchSizeRangeRule(min: 64, max: 3600),
                SlotLedgerPinnedGuardRule(limit: 4.2),
                SlotLedgerCodePrefixRule(prefix: "X"),
                SlotLedgerFloorValueRangeRule(min: 6.5, max: 3506.6),
                SlotLedgerRequiredPatientRefRule(message: "slot ledger needs a value"),
            ]
        )
    }
}
