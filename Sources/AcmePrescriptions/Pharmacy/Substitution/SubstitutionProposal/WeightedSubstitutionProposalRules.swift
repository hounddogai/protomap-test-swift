import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted substitution proposal must pass. Check returns its problems, or none.
    protocol WeightedSubstitutionProposalRule {
        func check(_ item: WeightedSubstitutionProposal) -> [String]
    }

    final class WeightedSubstitutionProposalCodeLengthRule: WeightedSubstitutionProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSubstitutionProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSubstitutionProposalPayerLengthRule: WeightedSubstitutionProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSubstitutionProposal) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSubstitutionProposalTitleLengthRule: WeightedSubstitutionProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSubstitutionProposal) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSubstitutionProposalRequiredCodeRule: WeightedSubstitutionProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSubstitutionProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted substitution proposal.
    final class WeightedSubstitutionProposalValidator {
        var rules: [any WeightedSubstitutionProposalRule]

        init(rules: [any WeightedSubstitutionProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSubstitutionProposal) -> [String] {
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

        func requireValid(_ item: WeightedSubstitutionProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSubstitutionProposal]) -> [String: [String]] {
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

    static func defaultWeightedSubstitutionProposalValidator() -> WeightedSubstitutionProposalValidator {
        return WeightedSubstitutionProposalValidator(
            rules: [
                WeightedSubstitutionProposalCodeLengthRule(maxLength: 86400),
                WeightedSubstitutionProposalPayerLengthRule(maxLength: 1000),
                WeightedSubstitutionProposalTitleLengthRule(maxLength: 32),
                WeightedSubstitutionProposalRequiredCodeRule(
                    message: "weighted substitution proposal needs this field"
                ),
            ]
        )
    }
}
