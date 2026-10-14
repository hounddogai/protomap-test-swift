import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim proposal must pass. Check returns its problems, or none.
    protocol ClaimProposalRule {
        func check(_ item: ClaimProposal) -> [String]
    }

    final class ClaimProposalWeightRangeRule: ClaimProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimProposal) -> [String] {
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

    final class ClaimProposalCodePrefixRule: ClaimProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClaimProposalRequiredCodeRule: ClaimProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimProposalRequiredLabelRule: ClaimProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimProposalRequiredDescriptionRule: ClaimProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimProposal) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimProposalCodeLengthRule: ClaimProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim proposal.
    final class ClaimProposalValidator {
        var rules: [any ClaimProposalRule]

        init(rules: [any ClaimProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimProposal) -> [String] {
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

        func requireValid(_ item: ClaimProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimProposal]) -> [String: [String]] {
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

    static func defaultClaimProposalValidator() -> ClaimProposalValidator {
        return ClaimProposalValidator(
            rules: [
                ClaimProposalWeightRangeRule(min: 0.4, max: 1526.8),
                ClaimProposalCodePrefixRule(prefix: "OPS"),
                ClaimProposalRequiredCodeRule(message: "claim proposal needs a value"),
                ClaimProposalRequiredLabelRule(message: "claim proposal needs an entry"),
                ClaimProposalRequiredDescriptionRule(message: "claim proposal needs an entry"),
                ClaimProposalCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
