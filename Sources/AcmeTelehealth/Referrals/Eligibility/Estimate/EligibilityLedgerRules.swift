import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility ledger must pass. Check returns its problems, or none.
    protocol EligibilityLedgerRule {
        func check(_ item: EligibilityLedger) -> [String]
    }

    final class EligibilityLedgerChecksumLengthRule: EligibilityLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityLedger) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityLedgerCodeLengthRule: EligibilityLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityLedgerRequiredLabelRule: EligibilityLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityLedgerEndsAtRangeRule: EligibilityLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityLedger) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityLedgerRequiredChecksumRule: EligibilityLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityLedger) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityLedgerActiveGuardRule: EligibilityLedgerRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: EligibilityLedger) -> [String] {
            if item.active && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility ledger.
    final class EligibilityLedgerValidator {
        var rules: [any EligibilityLedgerRule]

        init(rules: [any EligibilityLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityLedger]) -> [String: [String]] {
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

    static func defaultEligibilityLedgerValidator() -> EligibilityLedgerValidator {
        return EligibilityLedgerValidator(
            rules: [
                EligibilityLedgerChecksumLengthRule(maxLength: 120),
                EligibilityLedgerCodeLengthRule(maxLength: 16),
                EligibilityLedgerRequiredLabelRule(message: "eligibility ledger needs this field"),
                EligibilityLedgerEndsAtRangeRule(min: 1000, max: 1000),
                EligibilityLedgerRequiredChecksumRule(message: "eligibility ledger needs a value"),
                EligibilityLedgerActiveGuardRule(limit: 7.1),
            ]
        )
    }
}
