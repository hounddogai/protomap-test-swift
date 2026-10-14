import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled overtime proposal must pass. Check returns its problems, or none.
    protocol ScheduledOvertimeProposalRule {
        func check(_ item: ScheduledOvertimeProposal) -> [String]
    }

    final class ScheduledOvertimeProposalCodeLengthRule: ScheduledOvertimeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledOvertimeProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledOvertimeProposalRequiredNameRule: ScheduledOvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOvertimeProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOvertimeProposalRequiredCodeRule: ScheduledOvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOvertimeProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOvertimeProposalLabelLengthRule: ScheduledOvertimeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledOvertimeProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled overtime proposal.
    final class ScheduledOvertimeProposalValidator {
        var rules: [any ScheduledOvertimeProposalRule]

        init(rules: [any ScheduledOvertimeProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledOvertimeProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledOvertimeProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledOvertimeProposal]) -> [String: [String]] {
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

    static func defaultScheduledOvertimeProposalValidator() -> ScheduledOvertimeProposalValidator {
        return ScheduledOvertimeProposalValidator(
            rules: [
                ScheduledOvertimeProposalCodeLengthRule(maxLength: 86400),
                ScheduledOvertimeProposalRequiredNameRule(message: "scheduled overtime proposal needs an entry"),
                ScheduledOvertimeProposalRequiredCodeRule(message: "scheduled overtime proposal needs a value"),
                ScheduledOvertimeProposalLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
