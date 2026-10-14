import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient goal proposal must pass. Check returns its problems, or none.
    protocol LenientGoalProposalRule {
        func check(_ item: LenientGoalProposal) -> [String]
    }

    final class LenientGoalProposalRequiredTimezoneRule: LenientGoalProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientGoalProposal) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientGoalProposalCodePrefixRule: LenientGoalProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientGoalProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientGoalProposalRequiredLabelRule: LenientGoalProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientGoalProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientGoalProposalRequiredUnitRule: LenientGoalProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientGoalProposal) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient goal proposal.
    final class LenientGoalProposalValidator {
        var rules: [any LenientGoalProposalRule]

        init(rules: [any LenientGoalProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientGoalProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientGoalProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientGoalProposal]) -> [String: [String]] {
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

    static func defaultLenientGoalProposalValidator() -> LenientGoalProposalValidator {
        return LenientGoalProposalValidator(
            rules: [
                LenientGoalProposalRequiredTimezoneRule(message: "lenient goal proposal needs a value"),
                LenientGoalProposalCodePrefixRule(prefix: "ACM"),
                LenientGoalProposalRequiredLabelRule(message: "lenient goal proposal needs a value"),
                LenientGoalProposalRequiredUnitRule(message: "lenient goal proposal needs this field"),
            ]
        )
    }
}
