import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral ledger must pass. Check returns its problems, or none.
    protocol ReferralLedgerRule {
        func check(_ item: ReferralLedger) -> [String]
    }

    final class ReferralLedgerRequiredSpecialtyRule: ReferralLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralLedger) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralLedgerCodePrefixRule: ReferralLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferralLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferralLedgerNameLengthRule: ReferralLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralLedgerAcuityRangeRule: ReferralLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralLedger) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralLedgerTitleLengthRule: ReferralLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralLedgerBudgetRangeRule: ReferralLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralLedger) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral ledger.
    final class ReferralLedgerValidator {
        var rules: [any ReferralLedgerRule]

        init(rules: [any ReferralLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralLedger]) -> [String: [String]] {
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

    static func defaultReferralLedgerValidator() -> ReferralLedgerValidator {
        return ReferralLedgerValidator(
            rules: [
                ReferralLedgerRequiredSpecialtyRule(message: "referral ledger needs an entry"),
                ReferralLedgerCodePrefixRule(prefix: "REF"),
                ReferralLedgerNameLengthRule(maxLength: 80),
                ReferralLedgerAcuityRangeRule(min: 1000, max: 3600),
                ReferralLedgerTitleLengthRule(maxLength: 3600),
                ReferralLedgerBudgetRangeRule(min: 5.5, max: 3498.3),
            ]
        )
    }
}
