import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped handoff proposal must pass. Check returns its problems, or none.
    protocol CappedHandoffProposalRule {
        func check(_ item: CappedHandoffProposal) -> [String]
    }

    final class CappedHandoffProposalProcedureCodeLengthRule: CappedHandoffProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedHandoffProposal) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedHandoffProposalTitleLengthRule: CappedHandoffProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedHandoffProposal) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedHandoffProposalCodeLengthRule: CappedHandoffProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedHandoffProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedHandoffProposalRequiredProcedureCodeRule: CappedHandoffProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedHandoffProposal) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedHandoffProposalRequiredCodeRule: CappedHandoffProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedHandoffProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped handoff proposal.
    final class CappedHandoffProposalValidator {
        var rules: [any CappedHandoffProposalRule]

        init(rules: [any CappedHandoffProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedHandoffProposal) -> [String] {
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

        func requireValid(_ item: CappedHandoffProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedHandoffProposal]) -> [String: [String]] {
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

    static func defaultCappedHandoffProposalValidator() -> CappedHandoffProposalValidator {
        return CappedHandoffProposalValidator(
            rules: [
                CappedHandoffProposalProcedureCodeLengthRule(maxLength: 120),
                CappedHandoffProposalTitleLengthRule(maxLength: 255),
                CappedHandoffProposalCodeLengthRule(maxLength: 255),
                CappedHandoffProposalRequiredProcedureCodeRule(message: "capped handoff proposal needs a value"),
                CappedHandoffProposalRequiredCodeRule(message: "capped handoff proposal needs an entry"),
            ]
        )
    }
}
