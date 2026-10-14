import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding ledger must pass. Check returns its problems, or none.
    protocol RoundingLedgerRule {
        func check(_ item: RoundingLedger) -> [String]
    }

    final class RoundingLedgerPhoneLengthRule: RoundingLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingLedger) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingLedgerExpiresAtRangeRule: RoundingLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingLedger) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingLedgerRefillsRangeRule: RoundingLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingLedger) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding ledger.
    final class RoundingLedgerValidator {
        var rules: [any RoundingLedgerRule]

        init(rules: [any RoundingLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingLedger]) -> [String: [String]] {
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

    static func defaultRoundingLedgerValidator() -> RoundingLedgerValidator {
        return RoundingLedgerValidator(
            rules: [
                RoundingLedgerPhoneLengthRule(maxLength: 80),
                RoundingLedgerExpiresAtRangeRule(min: 255, max: 1000),
                RoundingLedgerRefillsRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
