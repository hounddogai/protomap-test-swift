import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted specimen proposal must pass. Check returns its problems, or none.
    protocol WeightedSpecimenProposalRule {
        func check(_ item: WeightedSpecimenProposal) -> [String]
    }

    final class WeightedSpecimenProposalRequiredFacilityRule: WeightedSpecimenProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenProposal) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSpecimenProposalRequiredTitleRule: WeightedSpecimenProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSpecimenProposalRequiredNameRule: WeightedSpecimenProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSpecimenProposalRequiredCodeRule: WeightedSpecimenProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted specimen proposal.
    final class WeightedSpecimenProposalValidator {
        var rules: [any WeightedSpecimenProposalRule]

        init(rules: [any WeightedSpecimenProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSpecimenProposal) -> [String] {
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

        func requireValid(_ item: WeightedSpecimenProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSpecimenProposal]) -> [String: [String]] {
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

    static func defaultWeightedSpecimenProposalValidator() -> WeightedSpecimenProposalValidator {
        return WeightedSpecimenProposalValidator(
            rules: [
                WeightedSpecimenProposalRequiredFacilityRule(message: "weighted specimen proposal needs a value"),
                WeightedSpecimenProposalRequiredTitleRule(message: "weighted specimen proposal needs a value"),
                WeightedSpecimenProposalRequiredNameRule(message: "weighted specimen proposal needs this field"),
                WeightedSpecimenProposalRequiredCodeRule(message: "weighted specimen proposal needs this field"),
            ]
        )
    }
}
