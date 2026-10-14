import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual referral proposal must pass. Check returns its problems, or none.
    protocol ManualReferralProposalRule {
        func check(_ item: ManualReferralProposal) -> [String]
    }

    final class ManualReferralProposalCodeLengthRule: ManualReferralProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualReferralProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualReferralProposalLabelLengthRule: ManualReferralProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualReferralProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualReferralProposalMaximumRangeRule: ManualReferralProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualReferralProposal) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualReferralProposalCodePrefixRule: ManualReferralProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualReferralProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual referral proposal.
    final class ManualReferralProposalValidator {
        var rules: [any ManualReferralProposalRule]

        init(rules: [any ManualReferralProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualReferralProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualReferralProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualReferralProposal]) -> [String: [String]] {
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

    static func defaultManualReferralProposalValidator() -> ManualReferralProposalValidator {
        return ManualReferralProposalValidator(
            rules: [
                ManualReferralProposalCodeLengthRule(maxLength: 255),
                ManualReferralProposalLabelLengthRule(maxLength: 1000),
                ManualReferralProposalMaximumRangeRule(min: 4.7, max: 2270.9),
                ManualReferralProposalCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
