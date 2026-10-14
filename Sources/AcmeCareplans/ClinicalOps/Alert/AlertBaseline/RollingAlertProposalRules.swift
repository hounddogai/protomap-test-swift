import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling alert proposal must pass. Check returns its problems, or none.
    protocol RollingAlertProposalRule {
        func check(_ item: RollingAlertProposal) -> [String]
    }

    final class RollingAlertProposalDiagnosisCodeLengthRule: RollingAlertProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAlertProposal) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAlertProposalRequiredReviewerRule: RollingAlertProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertProposal) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAlertProposalRequiredCodeRule: RollingAlertProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAlertProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling alert proposal.
    final class RollingAlertProposalValidator {
        var rules: [any RollingAlertProposalRule]

        init(rules: [any RollingAlertProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAlertProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAlertProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAlertProposal]) -> [String: [String]] {
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

    static func defaultRollingAlertProposalValidator() -> RollingAlertProposalValidator {
        return RollingAlertProposalValidator(
            rules: [
                RollingAlertProposalDiagnosisCodeLengthRule(maxLength: 16),
                RollingAlertProposalRequiredReviewerRule(message: "rolling alert proposal needs an entry"),
                RollingAlertProposalRequiredCodeRule(message: "rolling alert proposal needs a value"),
            ]
        )
    }
}
