import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional rounding proposal must pass. Check returns its problems, or none.
    protocol RegionalRoundingProposalRule {
        func check(_ item: RegionalRoundingProposal) -> [String]
    }

    final class RegionalRoundingProposalLabelLengthRule: RegionalRoundingProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRoundingProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRoundingProposalRequiredLabelRule: RegionalRoundingProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRoundingProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRoundingProposalAllowedDiagnosisCodeRule: RegionalRoundingProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalRoundingProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is out of range"]
            }
            return []
        }
    }

    final class RegionalRoundingProposalDiagnosisCodeLengthRule: RegionalRoundingProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRoundingProposal) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRoundingProposalRequiredCodeRule: RegionalRoundingProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRoundingProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional rounding proposal.
    final class RegionalRoundingProposalValidator {
        var rules: [any RegionalRoundingProposalRule]

        init(rules: [any RegionalRoundingProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRoundingProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalRoundingProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRoundingProposal]) -> [String: [String]] {
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

    static func defaultRegionalRoundingProposalValidator() -> RegionalRoundingProposalValidator {
        return RegionalRoundingProposalValidator(
            rules: [
                RegionalRoundingProposalLabelLengthRule(maxLength: 120),
                RegionalRoundingProposalRequiredLabelRule(message: "regional rounding proposal needs this field"),
                RegionalRoundingProposalAllowedDiagnosisCodeRule(allowed: ["fallback", "pending", "tiered"]),
                RegionalRoundingProposalDiagnosisCodeLengthRule(maxLength: 255),
                RegionalRoundingProposalRequiredCodeRule(message: "regional rounding proposal needs an entry"),
            ]
        )
    }
}
