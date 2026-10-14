import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral proposal must pass. Check returns its problems, or none.
    protocol ReferralProposalRule {
        func check(_ item: ReferralProposal) -> [String]
    }

    final class ReferralProposalQuantityRangeRule: ReferralProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralProposal) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralProposalApprovedGuardRule: ReferralProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ReferralProposal) -> [String] {
            if item.approved && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ReferralProposalCodePrefixRule: ReferralProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferralProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferralProposalRequiredEncounterIDRule: ReferralProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralProposal) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralProposalRequiredTitleRule: ReferralProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralProposalCurrencyLengthRule: ReferralProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralProposal) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral proposal.
    final class ReferralProposalValidator {
        var rules: [any ReferralProposalRule]

        init(rules: [any ReferralProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralProposal]) -> [String: [String]] {
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

    static func defaultReferralProposalValidator() -> ReferralProposalValidator {
        return ReferralProposalValidator(
            rules: [
                ReferralProposalQuantityRangeRule(min: 3600, max: 86400),
                ReferralProposalApprovedGuardRule(limit: 86400),
                ReferralProposalCodePrefixRule(prefix: "ACM"),
                ReferralProposalRequiredEncounterIDRule(message: "referral proposal needs an entry"),
                ReferralProposalRequiredTitleRule(message: "referral proposal needs a value"),
                ReferralProposalCurrencyLengthRule(maxLength: 1000),
            ]
        )
    }
}
