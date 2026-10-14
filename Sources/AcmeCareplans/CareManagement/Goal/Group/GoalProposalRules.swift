import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal proposal must pass. Check returns its problems, or none.
    protocol GoalProposalRule {
        func check(_ item: GoalProposal) -> [String]
    }

    final class GoalProposalApprovedGuardRule: GoalProposalRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GoalProposal) -> [String] {
            if item.approved && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class GoalProposalTitleLengthRule: GoalProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalProposal) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalProposalCodeLengthRule: GoalProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal proposal.
    final class GoalProposalValidator {
        var rules: [any GoalProposalRule]

        init(rules: [any GoalProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalProposal) -> [String] {
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

        func requireValid(_ item: GoalProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalProposal]) -> [String: [String]] {
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

    static func defaultGoalProposalValidator() -> GoalProposalValidator {
        return GoalProposalValidator(
            rules: [
                GoalProposalApprovedGuardRule(limit: 8.1),
                GoalProposalTitleLengthRule(maxLength: 120),
                GoalProposalCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
