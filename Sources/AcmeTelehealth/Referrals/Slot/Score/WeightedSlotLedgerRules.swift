import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted slot ledger must pass. Check returns its problems, or none.
    protocol WeightedSlotLedgerRule {
        func check(_ item: WeightedSlotLedger) -> [String]
    }

    final class WeightedSlotLedgerRequiredCodeRule: WeightedSlotLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSlotLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSlotLedgerSpecialtyLengthRule: WeightedSlotLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSlotLedger) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSlotLedgerRequiredLabelRule: WeightedSlotLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSlotLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSlotLedgerWeightRangeRule: WeightedSlotLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSlotLedger) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedSlotLedgerCodeLengthRule: WeightedSlotLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSlotLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted slot ledger.
    final class WeightedSlotLedgerValidator {
        var rules: [any WeightedSlotLedgerRule]

        init(rules: [any WeightedSlotLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSlotLedger) -> [String] {
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

        func requireValid(_ item: WeightedSlotLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSlotLedger]) -> [String: [String]] {
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

    static func defaultWeightedSlotLedgerValidator() -> WeightedSlotLedgerValidator {
        return WeightedSlotLedgerValidator(
            rules: [
                WeightedSlotLedgerRequiredCodeRule(message: "weighted slot ledger needs this field"),
                WeightedSlotLedgerSpecialtyLengthRule(maxLength: 86400),
                WeightedSlotLedgerRequiredLabelRule(message: "weighted slot ledger needs this field"),
                WeightedSlotLedgerWeightRangeRule(min: 2.0, max: 134.3),
                WeightedSlotLedgerCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
