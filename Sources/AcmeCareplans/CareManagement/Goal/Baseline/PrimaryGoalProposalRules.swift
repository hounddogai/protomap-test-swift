import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary goal proposal must pass. Check returns its problems, or none.
    protocol PrimaryGoalProposalRule {
        func check(_ item: PrimaryGoalProposal) -> [String]
    }

    final class PrimaryGoalProposalAllowedLabelRule: PrimaryGoalProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryGoalProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class PrimaryGoalProposalCodePrefixRule: PrimaryGoalProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryGoalProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryGoalProposalRequiredLabelRule: PrimaryGoalProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryGoalProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary goal proposal.
    final class PrimaryGoalProposalValidator {
        var rules: [any PrimaryGoalProposalRule]

        init(rules: [any PrimaryGoalProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryGoalProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryGoalProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryGoalProposal]) -> [String: [String]] {
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

    static func defaultPrimaryGoalProposalValidator() -> PrimaryGoalProposalValidator {
        return PrimaryGoalProposalValidator(
            rules: [
                PrimaryGoalProposalAllowedLabelRule(allowed: ["scheduled", "pending", "weighted"]),
                PrimaryGoalProposalCodePrefixRule(prefix: "X"),
                PrimaryGoalProposalRequiredLabelRule(message: "primary goal proposal needs a value"),
            ]
        )
    }
}
