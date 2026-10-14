import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up ledger must pass. Check returns its problems, or none.
    protocol FollowUpLedgerRule {
        func check(_ item: FollowUpLedger) -> [String]
    }

    final class FollowUpLedgerAllowedAllergyRule: FollowUpLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is too long"]
            }
            return []
        }
    }

    final class FollowUpLedgerCurrencyLengthRule: FollowUpLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpLedger) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpLedgerRequiredNameRule: FollowUpLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpLedgerNameLengthRule: FollowUpLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up ledger.
    final class FollowUpLedgerValidator {
        var rules: [any FollowUpLedgerRule]

        init(rules: [any FollowUpLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpLedger]) -> [String: [String]] {
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

    static func defaultFollowUpLedgerValidator() -> FollowUpLedgerValidator {
        return FollowUpLedgerValidator(
            rules: [
                FollowUpLedgerAllowedAllergyRule(allowed: []),
                FollowUpLedgerCurrencyLengthRule(maxLength: 16),
                FollowUpLedgerRequiredNameRule(message: "follow up ledger needs an entry"),
                FollowUpLedgerNameLengthRule(maxLength: 255),
            ]
        )
    }
}
