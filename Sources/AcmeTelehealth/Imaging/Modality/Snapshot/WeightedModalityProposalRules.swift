import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted modality proposal must pass. Check returns its problems, or none.
    protocol WeightedModalityProposalRule {
        func check(_ item: WeightedModalityProposal) -> [String]
    }

    final class WeightedModalityProposalNameLengthRule: WeightedModalityProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedModalityProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedModalityProposalAllowedExternalRefRule: WeightedModalityProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedModalityProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is below minimum"]
            }
            return []
        }
    }

    final class WeightedModalityProposalRequiredExternalRefRule: WeightedModalityProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedModalityProposal) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted modality proposal.
    final class WeightedModalityProposalValidator {
        var rules: [any WeightedModalityProposalRule]

        init(rules: [any WeightedModalityProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedModalityProposal) -> [String] {
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

        func requireValid(_ item: WeightedModalityProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedModalityProposal]) -> [String: [String]] {
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

    static func defaultWeightedModalityProposalValidator() -> WeightedModalityProposalValidator {
        return WeightedModalityProposalValidator(
            rules: [
                WeightedModalityProposalNameLengthRule(maxLength: 3600),
                WeightedModalityProposalAllowedExternalRefRule(allowed: ["rolling"]),
                WeightedModalityProposalRequiredExternalRefRule(
                    message: "weighted modality proposal needs this field"
                ),
            ]
        )
    }
}
