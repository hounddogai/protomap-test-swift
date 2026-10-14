import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment proposal must pass. Check returns its problems, or none.
    protocol AssessmentProposalRule {
        func check(_ item: AssessmentProposal) -> [String]
    }

    final class AssessmentProposalVersionRangeRule: AssessmentProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentProposal) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentProposalPatientRefLengthRule: AssessmentProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentProposal) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentProposalCodePrefixRule: AssessmentProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentProposalRequiredExternalRefRule: AssessmentProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentProposal) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a assessment proposal.
    final class AssessmentProposalValidator {
        var rules: [any AssessmentProposalRule]

        init(rules: [any AssessmentProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentProposal) -> [String] {
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

        func requireValid(_ item: AssessmentProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentProposal]) -> [String: [String]] {
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

    static func defaultAssessmentProposalValidator() -> AssessmentProposalValidator {
        return AssessmentProposalValidator(
            rules: [
                AssessmentProposalVersionRangeRule(min: 1000, max: 3600),
                AssessmentProposalPatientRefLengthRule(maxLength: 1000),
                AssessmentProposalCodePrefixRule(prefix: "X"),
                AssessmentProposalRequiredExternalRefRule(message: "assessment proposal needs an entry"),
            ]
        )
    }
}
