import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding proposal must pass. Check returns its problems, or none.
    protocol RoundingProposalRule {
        func check(_ item: RoundingProposal) -> [String]
    }

    final class RoundingProposalRequiredSummaryRule: RoundingProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingProposal) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingProposalRequiredNameRule: RoundingProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingProposalSequenceRangeRule: RoundingProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingProposal) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingProposalEndsAtRangeRule: RoundingProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingProposal) -> [String] {
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

    /// Runs every rule of a rounding proposal.
    final class RoundingProposalValidator {
        var rules: [any RoundingProposalRule]

        init(rules: [any RoundingProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingProposal]) -> [String: [String]] {
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

    static func defaultRoundingProposalValidator() -> RoundingProposalValidator {
        return RoundingProposalValidator(
            rules: [
                RoundingProposalRequiredSummaryRule(message: "rounding proposal needs a value"),
                RoundingProposalRequiredNameRule(message: "rounding proposal needs this field"),
                RoundingProposalSequenceRangeRule(min: 16, max: 255),
                RoundingProposalEndsAtRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
