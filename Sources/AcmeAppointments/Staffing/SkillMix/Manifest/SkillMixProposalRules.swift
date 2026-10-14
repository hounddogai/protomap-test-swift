import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix proposal must pass. Check returns its problems, or none.
    protocol SkillMixProposalRule {
        func check(_ item: SkillMixProposal) -> [String]
    }

    final class SkillMixProposalProcedureCodeLengthRule: SkillMixProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixProposal) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixProposalLabelLengthRule: SkillMixProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixProposalCreatedAtRangeRule: SkillMixProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixProposal) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixProposalRequiredProcedureCodeRule: SkillMixProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixProposal) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixProposalRequiredLabelRule: SkillMixProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixProposalAttemptsRangeRule: SkillMixProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixProposal) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a skill mix proposal.
    final class SkillMixProposalValidator {
        var rules: [any SkillMixProposalRule]

        init(rules: [any SkillMixProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixProposal]) -> [String: [String]] {
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

    static func defaultSkillMixProposalValidator() -> SkillMixProposalValidator {
        return SkillMixProposalValidator(
            rules: [
                SkillMixProposalProcedureCodeLengthRule(maxLength: 32),
                SkillMixProposalLabelLengthRule(maxLength: 1000),
                SkillMixProposalCreatedAtRangeRule(min: 80, max: 255),
                SkillMixProposalRequiredProcedureCodeRule(message: "skill mix proposal needs an entry"),
                SkillMixProposalRequiredLabelRule(message: "skill mix proposal needs an entry"),
                SkillMixProposalAttemptsRangeRule(min: 64, max: 255),
            ]
        )
    }
}
