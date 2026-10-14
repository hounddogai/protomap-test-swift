import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched risk score proposal must pass. Check returns its problems, or none.
    protocol BatchedRiskScoreProposalRule {
        func check(_ item: BatchedRiskScoreProposal) -> [String]
    }

    final class BatchedRiskScoreProposalWeightRangeRule: BatchedRiskScoreProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRiskScoreProposal) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedRiskScoreProposalRequiredBedRule: BatchedRiskScoreProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRiskScoreProposal) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRiskScoreProposalAllowedCodeRule: BatchedRiskScoreProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedRiskScoreProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class BatchedRiskScoreProposalCodeLengthRule: BatchedRiskScoreProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRiskScoreProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedRiskScoreProposalCodePrefixRule: BatchedRiskScoreProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedRiskScoreProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched risk score proposal.
    final class BatchedRiskScoreProposalValidator {
        var rules: [any BatchedRiskScoreProposalRule]

        init(rules: [any BatchedRiskScoreProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRiskScoreProposal) -> [String] {
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

        func requireValid(_ item: BatchedRiskScoreProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRiskScoreProposal]) -> [String: [String]] {
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

    static func defaultBatchedRiskScoreProposalValidator() -> BatchedRiskScoreProposalValidator {
        return BatchedRiskScoreProposalValidator(
            rules: [
                BatchedRiskScoreProposalWeightRangeRule(min: 7.5, max: 3809.1),
                BatchedRiskScoreProposalRequiredBedRule(message: "batched risk score proposal needs a value"),
                BatchedRiskScoreProposalAllowedCodeRule(allowed: []),
                BatchedRiskScoreProposalCodeLengthRule(maxLength: 86400),
                BatchedRiskScoreProposalCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
