import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy goal proposal must pass. Check returns its problems, or none.
    protocol LegacyGoalProposalRule {
        func check(_ item: LegacyGoalProposal) -> [String]
    }

    final class LegacyGoalProposalUpdatedAtRangeRule: LegacyGoalProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyGoalProposal) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyGoalProposalCodeLengthRule: LegacyGoalProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyGoalProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyGoalProposalRequiredSourceRule: LegacyGoalProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyGoalProposal) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyGoalProposalNotesLengthRule: LegacyGoalProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyGoalProposal) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyGoalProposalSourceLengthRule: LegacyGoalProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyGoalProposal) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy goal proposal.
    final class LegacyGoalProposalValidator {
        var rules: [any LegacyGoalProposalRule]

        init(rules: [any LegacyGoalProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyGoalProposal) -> [String] {
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

        func requireValid(_ item: LegacyGoalProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyGoalProposal]) -> [String: [String]] {
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

    static func defaultLegacyGoalProposalValidator() -> LegacyGoalProposalValidator {
        return LegacyGoalProposalValidator(
            rules: [
                LegacyGoalProposalUpdatedAtRangeRule(min: 64, max: 255),
                LegacyGoalProposalCodeLengthRule(maxLength: 32),
                LegacyGoalProposalRequiredSourceRule(message: "legacy goal proposal needs an entry"),
                LegacyGoalProposalNotesLengthRule(maxLength: 80),
                LegacyGoalProposalSourceLengthRule(maxLength: 80),
            ]
        )
    }
}
