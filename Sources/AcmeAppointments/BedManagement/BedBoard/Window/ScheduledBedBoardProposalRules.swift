import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled bed board proposal must pass. Check returns its problems, or none.
    protocol ScheduledBedBoardProposalRule {
        func check(_ item: ScheduledBedBoardProposal) -> [String]
    }

    final class ScheduledBedBoardProposalPinnedGuardRule: ScheduledBedBoardProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledBedBoardProposal) -> [String] {
            if item.pinned && (item.acuity > limit) {
                return ["acuity \(item.acuity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class ScheduledBedBoardProposalRequiredLabelRule: ScheduledBedBoardProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledBedBoardProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledBedBoardProposalLabelLengthRule: ScheduledBedBoardProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledBedBoardProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled bed board proposal.
    final class ScheduledBedBoardProposalValidator {
        var rules: [any ScheduledBedBoardProposalRule]

        init(rules: [any ScheduledBedBoardProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledBedBoardProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledBedBoardProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledBedBoardProposal]) -> [String: [String]] {
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

    static func defaultScheduledBedBoardProposalValidator() -> ScheduledBedBoardProposalValidator {
        return ScheduledBedBoardProposalValidator(
            rules: [
                ScheduledBedBoardProposalPinnedGuardRule(limit: 3600),
                ScheduledBedBoardProposalRequiredLabelRule(message: "scheduled bed board proposal needs a value"),
                ScheduledBedBoardProposalLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
