import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program proposal must pass. Check returns its problems, or none.
    protocol ProgramProposalRule {
        func check(_ item: ProgramProposal) -> [String]
    }

    final class ProgramProposalRequiredLabelRule: ProgramProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramProposalRequiredSegmentRule: ProgramProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramProposal) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramProposalCodePrefixRule: ProgramProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramProposalCodeLengthRule: ProgramProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a program proposal.
    final class ProgramProposalValidator {
        var rules: [any ProgramProposalRule]

        init(rules: [any ProgramProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramProposal) -> [String] {
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

        func requireValid(_ item: ProgramProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramProposal]) -> [String: [String]] {
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

    static func defaultProgramProposalValidator() -> ProgramProposalValidator {
        return ProgramProposalValidator(
            rules: [
                ProgramProposalRequiredLabelRule(message: "program proposal needs an entry"),
                ProgramProposalRequiredSegmentRule(message: "program proposal needs a value"),
                ProgramProposalCodePrefixRule(prefix: "REF"),
                ProgramProposalCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
