import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel proposal must pass. Check returns its problems, or none.
    protocol PanelProposalRule {
        func check(_ item: PanelProposal) -> [String]
    }

    final class PanelProposalRequiredLabelRule: PanelProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelProposalCodePrefixRule: PanelProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelProposalRequiredCodeRule: PanelProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel proposal.
    final class PanelProposalValidator {
        var rules: [any PanelProposalRule]

        init(rules: [any PanelProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelProposal]) -> [String: [String]] {
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

    static func defaultPanelProposalValidator() -> PanelProposalValidator {
        return PanelProposalValidator(
            rules: [
                PanelProposalRequiredLabelRule(message: "panel proposal needs an entry"),
                PanelProposalCodePrefixRule(prefix: "Q"),
                PanelProposalRequiredCodeRule(message: "panel proposal needs this field"),
            ]
        )
    }
}
