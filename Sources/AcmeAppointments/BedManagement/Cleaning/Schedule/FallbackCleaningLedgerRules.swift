import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback cleaning ledger must pass. Check returns its problems, or none.
    protocol FallbackCleaningLedgerRule {
        func check(_ item: FallbackCleaningLedger) -> [String]
    }

    final class FallbackCleaningLedgerCodePrefixRule: FallbackCleaningLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCleaningLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackCleaningLedgerStartsAtRangeRule: FallbackCleaningLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCleaningLedger) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCleaningLedgerRequiredFacilityRule: FallbackCleaningLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCleaningLedger) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCleaningLedgerFacilityLengthRule: FallbackCleaningLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCleaningLedger) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback cleaning ledger.
    final class FallbackCleaningLedgerValidator {
        var rules: [any FallbackCleaningLedgerRule]

        init(rules: [any FallbackCleaningLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCleaningLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCleaningLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCleaningLedger]) -> [String: [String]] {
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

    static func defaultFallbackCleaningLedgerValidator() -> FallbackCleaningLedgerValidator {
        return FallbackCleaningLedgerValidator(
            rules: [
                FallbackCleaningLedgerCodePrefixRule(prefix: "Q"),
                FallbackCleaningLedgerStartsAtRangeRule(min: 64, max: 86400),
                FallbackCleaningLedgerRequiredFacilityRule(message: "fallback cleaning ledger needs this field"),
                FallbackCleaningLedgerFacilityLengthRule(maxLength: 86400),
            ]
        )
    }
}
