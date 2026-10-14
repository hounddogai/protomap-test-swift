import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall proposal must pass. Check returns its problems, or none.
    protocol RecallProposalRule {
        func check(_ item: RecallProposal) -> [String]
    }

    final class RecallProposalChannelLengthRule: RecallProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallProposal) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallProposalRequiredCodeRule: RecallProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallProposalRequiredTimezoneRule: RecallProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallProposal) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall proposal.
    final class RecallProposalValidator {
        var rules: [any RecallProposalRule]

        init(rules: [any RecallProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallProposal]) -> [String: [String]] {
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

    static func defaultRecallProposalValidator() -> RecallProposalValidator {
        return RecallProposalValidator(
            rules: [
                RecallProposalChannelLengthRule(maxLength: 86400),
                RecallProposalRequiredCodeRule(message: "recall proposal needs a value"),
                RecallProposalRequiredTimezoneRule(message: "recall proposal needs a value"),
            ]
        )
    }
}
