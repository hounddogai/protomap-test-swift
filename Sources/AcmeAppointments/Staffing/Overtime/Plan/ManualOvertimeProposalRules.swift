import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual overtime proposal must pass. Check returns its problems, or none.
    protocol ManualOvertimeProposalRule {
        func check(_ item: ManualOvertimeProposal) -> [String]
    }

    final class ManualOvertimeProposalArchivedGuardRule: ManualOvertimeProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ManualOvertimeProposal) -> [String] {
            if item.archived && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ManualOvertimeProposalCodePrefixRule: ManualOvertimeProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualOvertimeProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualOvertimeProposalCodeLengthRule: ManualOvertimeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOvertimeProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOvertimeProposalRequiredAllergyRule: ManualOvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualOvertimeProposal) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual overtime proposal.
    final class ManualOvertimeProposalValidator {
        var rules: [any ManualOvertimeProposalRule]

        init(rules: [any ManualOvertimeProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualOvertimeProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualOvertimeProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualOvertimeProposal]) -> [String: [String]] {
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

    static func defaultManualOvertimeProposalValidator() -> ManualOvertimeProposalValidator {
        return ManualOvertimeProposalValidator(
            rules: [
                ManualOvertimeProposalArchivedGuardRule(limit: 1000),
                ManualOvertimeProposalCodePrefixRule(prefix: "X"),
                ManualOvertimeProposalCodeLengthRule(maxLength: 120),
                ManualOvertimeProposalRequiredAllergyRule(message: "manual overtime proposal needs an entry"),
            ]
        )
    }
}
