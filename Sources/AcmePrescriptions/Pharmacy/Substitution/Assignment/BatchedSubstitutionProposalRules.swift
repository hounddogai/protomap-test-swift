import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched substitution proposal must pass. Check returns its problems, or none.
    protocol BatchedSubstitutionProposalRule {
        func check(_ item: BatchedSubstitutionProposal) -> [String]
    }

    final class BatchedSubstitutionProposalVersionRangeRule: BatchedSubstitutionProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSubstitutionProposal) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSubstitutionProposalAcuityRangeRule: BatchedSubstitutionProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSubstitutionProposal) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSubstitutionProposalCurrencyLengthRule: BatchedSubstitutionProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSubstitutionProposal) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched substitution proposal.
    final class BatchedSubstitutionProposalValidator {
        var rules: [any BatchedSubstitutionProposalRule]

        init(rules: [any BatchedSubstitutionProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSubstitutionProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedSubstitutionProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSubstitutionProposal]) -> [String: [String]] {
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

    static func defaultBatchedSubstitutionProposalValidator() -> BatchedSubstitutionProposalValidator {
        return BatchedSubstitutionProposalValidator(
            rules: [
                BatchedSubstitutionProposalVersionRangeRule(min: 32, max: 120),
                BatchedSubstitutionProposalAcuityRangeRule(min: 32, max: 64),
                BatchedSubstitutionProposalCurrencyLengthRule(maxLength: 32),
            ]
        )
    }
}
