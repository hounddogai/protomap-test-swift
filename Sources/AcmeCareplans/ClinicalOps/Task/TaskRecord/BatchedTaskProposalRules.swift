import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched task proposal must pass. Check returns its problems, or none.
    protocol BatchedTaskProposalRule {
        func check(_ item: BatchedTaskProposal) -> [String]
    }

    final class BatchedTaskProposalLabelLengthRule: BatchedTaskProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedTaskProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedTaskProposalVisibleGuardRule: BatchedTaskProposalRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BatchedTaskProposal) -> [String] {
            if item.visible && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class BatchedTaskProposalScoreRangeRule: BatchedTaskProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedTaskProposal) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched task proposal.
    final class BatchedTaskProposalValidator {
        var rules: [any BatchedTaskProposalRule]

        init(rules: [any BatchedTaskProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedTaskProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedTaskProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedTaskProposal]) -> [String: [String]] {
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

    static func defaultBatchedTaskProposalValidator() -> BatchedTaskProposalValidator {
        return BatchedTaskProposalValidator(
            rules: [
                BatchedTaskProposalLabelLengthRule(maxLength: 16),
                BatchedTaskProposalVisibleGuardRule(limit: 9.4),
                BatchedTaskProposalScoreRangeRule(min: 6.0, max: 4233.6),
            ]
        )
    }
}
