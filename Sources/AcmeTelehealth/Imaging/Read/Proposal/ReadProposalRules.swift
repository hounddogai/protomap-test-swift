import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read proposal must pass. Check returns its problems, or none.
    protocol ReadProposalRule {
        func check(_ item: ReadProposal) -> [String]
    }

    final class ReadProposalRequiredCodeRule: ReadProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadProposalCodeLengthRule: ReadProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadProposalSummaryLengthRule: ReadProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadProposal) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read proposal.
    final class ReadProposalValidator {
        var rules: [any ReadProposalRule]

        init(rules: [any ReadProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadProposal]) -> [String: [String]] {
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

    static func defaultReadProposalValidator() -> ReadProposalValidator {
        return ReadProposalValidator(
            rules: [
                ReadProposalRequiredCodeRule(message: "read proposal needs an entry"),
                ReadProposalCodeLengthRule(maxLength: 3600),
                ReadProposalSummaryLengthRule(maxLength: 80),
            ]
        )
    }
}
