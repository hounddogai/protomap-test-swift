import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict slot ledger must pass. Check returns its problems, or none.
    protocol StrictSlotLedgerRule {
        func check(_ item: StrictSlotLedger) -> [String]
    }

    final class StrictSlotLedgerLocaleLengthRule: StrictSlotLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSlotLedger) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSlotLedgerRequiredCodeRule: StrictSlotLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSlotLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSlotLedgerWeightRangeRule: StrictSlotLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSlotLedger) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictSlotLedgerRequiredLocaleRule: StrictSlotLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSlotLedger) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSlotLedgerSegmentLengthRule: StrictSlotLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSlotLedger) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict slot ledger.
    final class StrictSlotLedgerValidator {
        var rules: [any StrictSlotLedgerRule]

        init(rules: [any StrictSlotLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSlotLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictSlotLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSlotLedger]) -> [String: [String]] {
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

    static func defaultStrictSlotLedgerValidator() -> StrictSlotLedgerValidator {
        return StrictSlotLedgerValidator(
            rules: [
                StrictSlotLedgerLocaleLengthRule(maxLength: 255),
                StrictSlotLedgerRequiredCodeRule(message: "strict slot ledger needs an entry"),
                StrictSlotLedgerWeightRangeRule(min: 4.4, max: 2947.1),
                StrictSlotLedgerRequiredLocaleRule(message: "strict slot ledger needs a value"),
                StrictSlotLedgerSegmentLengthRule(maxLength: 32),
            ]
        )
    }
}
