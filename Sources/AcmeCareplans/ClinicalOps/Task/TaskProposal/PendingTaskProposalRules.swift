import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending task proposal must pass. Check returns its problems, or none.
    protocol PendingTaskProposalRule {
        func check(_ item: PendingTaskProposal) -> [String]
    }

    final class PendingTaskProposalCodeLengthRule: PendingTaskProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingTaskProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingTaskProposalCodePrefixRule: PendingTaskProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingTaskProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingTaskProposalPatientRefLengthRule: PendingTaskProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingTaskProposal) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending task proposal.
    final class PendingTaskProposalValidator {
        var rules: [any PendingTaskProposalRule]

        init(rules: [any PendingTaskProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingTaskProposal) -> [String] {
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

        func requireValid(_ item: PendingTaskProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingTaskProposal]) -> [String: [String]] {
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

    static func defaultPendingTaskProposalValidator() -> PendingTaskProposalValidator {
        return PendingTaskProposalValidator(
            rules: [
                PendingTaskProposalCodeLengthRule(maxLength: 120),
                PendingTaskProposalCodePrefixRule(prefix: "X"),
                PendingTaskProposalPatientRefLengthRule(maxLength: 32),
            ]
        )
    }
}
