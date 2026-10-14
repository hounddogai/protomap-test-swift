import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted referral proposal must pass. Check returns its problems, or none.
    protocol WeightedReferralProposalRule {
        func check(_ item: WeightedReferralProposal) -> [String]
    }

    final class WeightedReferralProposalThresholdRangeRule: WeightedReferralProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReferralProposal) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedReferralProposalCodeLengthRule: WeightedReferralProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReferralProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReferralProposalAllowedLabelRule: WeightedReferralProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedReferralProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted referral proposal.
    final class WeightedReferralProposalValidator {
        var rules: [any WeightedReferralProposalRule]

        init(rules: [any WeightedReferralProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReferralProposal) -> [String] {
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

        func requireValid(_ item: WeightedReferralProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReferralProposal]) -> [String: [String]] {
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

    static func defaultWeightedReferralProposalValidator() -> WeightedReferralProposalValidator {
        return WeightedReferralProposalValidator(
            rules: [
                WeightedReferralProposalThresholdRangeRule(min: 7.7, max: 1089.7),
                WeightedReferralProposalCodeLengthRule(maxLength: 3600),
                WeightedReferralProposalAllowedLabelRule(allowed: ["legacy", "adaptive"]),
            ]
        )
    }
}
