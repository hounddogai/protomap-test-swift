import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim ledger must pass. Check returns its problems, or none.
    protocol ClaimLedgerRule {
        func check(_ item: ClaimLedger) -> [String]
    }

    final class ClaimLedgerCodeLengthRule: ClaimLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimLedgerAllowedCodeRule: ClaimLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class ClaimLedgerVisitMinutesRangeRule: ClaimLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimLedger) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimLedgerAmountRangeRule: ClaimLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimLedger) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a claim ledger.
    final class ClaimLedgerValidator {
        var rules: [any ClaimLedgerRule]

        init(rules: [any ClaimLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimLedger) -> [String] {
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

        func requireValid(_ item: ClaimLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimLedger]) -> [String: [String]] {
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

    static func defaultClaimLedgerValidator() -> ClaimLedgerValidator {
        return ClaimLedgerValidator(
            rules: [
                ClaimLedgerCodeLengthRule(maxLength: 80),
                ClaimLedgerAllowedCodeRule(allowed: ["seasonal", "lenient", "global"]),
                ClaimLedgerVisitMinutesRangeRule(min: 32, max: 120),
                ClaimLedgerAmountRangeRule(min: 1.7, max: 2817.3),
            ]
        )
    }
}
