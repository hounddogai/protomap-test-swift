import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled witness proposal must pass. Check returns its problems, or none.
    protocol ScheduledWitnessProposalRule {
        func check(_ item: ScheduledWitnessProposal) -> [String]
    }

    final class ScheduledWitnessProposalRequiredProcedureCodeRule: ScheduledWitnessProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledWitnessProposal) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledWitnessProposalRequiredCodeRule: ScheduledWitnessProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledWitnessProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledWitnessProposalRequiredSourceRule: ScheduledWitnessProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledWitnessProposal) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledWitnessProposalPriorityRangeRule: ScheduledWitnessProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledWitnessProposal) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled witness proposal.
    final class ScheduledWitnessProposalValidator {
        var rules: [any ScheduledWitnessProposalRule]

        init(rules: [any ScheduledWitnessProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledWitnessProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledWitnessProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledWitnessProposal]) -> [String: [String]] {
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

    static func defaultScheduledWitnessProposalValidator() -> ScheduledWitnessProposalValidator {
        return ScheduledWitnessProposalValidator(
            rules: [
                ScheduledWitnessProposalRequiredProcedureCodeRule(
                    message: "scheduled witness proposal needs this field"
                ),
                ScheduledWitnessProposalRequiredCodeRule(message: "scheduled witness proposal needs a value"),
                ScheduledWitnessProposalRequiredSourceRule(message: "scheduled witness proposal needs an entry"),
                ScheduledWitnessProposalPriorityRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
