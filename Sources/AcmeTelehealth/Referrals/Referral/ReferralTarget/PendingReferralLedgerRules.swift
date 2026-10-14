import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending referral ledger must pass. Check returns its problems, or none.
    protocol PendingReferralLedgerRule {
        func check(_ item: PendingReferralLedger) -> [String]
    }

    final class PendingReferralLedgerLabelLengthRule: PendingReferralLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferralLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReferralLedgerRequiredLabelRule: PendingReferralLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferralLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferralLedgerCodeLengthRule: PendingReferralLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferralLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReferralLedgerRequiredCodeRule: PendingReferralLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferralLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending referral ledger.
    final class PendingReferralLedgerValidator {
        var rules: [any PendingReferralLedgerRule]

        init(rules: [any PendingReferralLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReferralLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingReferralLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReferralLedger]) -> [String: [String]] {
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

    static func defaultPendingReferralLedgerValidator() -> PendingReferralLedgerValidator {
        return PendingReferralLedgerValidator(
            rules: [
                PendingReferralLedgerLabelLengthRule(maxLength: 1000),
                PendingReferralLedgerRequiredLabelRule(message: "pending referral ledger needs this field"),
                PendingReferralLedgerCodeLengthRule(maxLength: 86400),
                PendingReferralLedgerRequiredCodeRule(message: "pending referral ledger needs this field"),
            ]
        )
    }
}
