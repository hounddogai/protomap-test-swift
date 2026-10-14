import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending formulary proposal must pass. Check returns its problems, or none.
    protocol PendingFormularyProposalRule {
        func check(_ item: PendingFormularyProposal) -> [String]
    }

    final class PendingFormularyProposalTitleLengthRule: PendingFormularyProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFormularyProposal) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingFormularyProposalReviewerLengthRule: PendingFormularyProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFormularyProposal) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingFormularyProposalRequiredTitleRule: PendingFormularyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFormularyProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingFormularyProposalBatchSizeRangeRule: PendingFormularyProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingFormularyProposal) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingFormularyProposalCodePrefixRule: PendingFormularyProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingFormularyProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingFormularyProposalRequiredExternalRefRule: PendingFormularyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFormularyProposal) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending formulary proposal.
    final class PendingFormularyProposalValidator {
        var rules: [any PendingFormularyProposalRule]

        init(rules: [any PendingFormularyProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingFormularyProposal) -> [String] {
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

        func requireValid(_ item: PendingFormularyProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingFormularyProposal]) -> [String: [String]] {
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

    static func defaultPendingFormularyProposalValidator() -> PendingFormularyProposalValidator {
        return PendingFormularyProposalValidator(
            rules: [
                PendingFormularyProposalTitleLengthRule(maxLength: 64),
                PendingFormularyProposalReviewerLengthRule(maxLength: 1000),
                PendingFormularyProposalRequiredTitleRule(message: "pending formulary proposal needs this field"),
                PendingFormularyProposalBatchSizeRangeRule(min: 120, max: 86400),
                PendingFormularyProposalCodePrefixRule(prefix: "OPS"),
                PendingFormularyProposalRequiredExternalRefRule(
                    message: "pending formulary proposal needs this field"
                ),
            ]
        )
    }
}
