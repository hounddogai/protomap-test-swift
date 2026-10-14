import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility proposal must pass. Check returns its problems, or none.
    protocol EligibilityProposalRule {
        func check(_ item: EligibilityProposal) -> [String]
    }

    final class EligibilityProposalAllowedLabelRule: EligibilityProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class EligibilityProposalRequiredLabelRule: EligibilityProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityProposalCodeLengthRule: EligibilityProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityProposalLabelLengthRule: EligibilityProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityProposalCodePrefixRule: EligibilityProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityProposalDiagnosisCodeLengthRule: EligibilityProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityProposal) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility proposal.
    final class EligibilityProposalValidator {
        var rules: [any EligibilityProposalRule]

        init(rules: [any EligibilityProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityProposal) -> [String] {
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

        func requireValid(_ item: EligibilityProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityProposal]) -> [String: [String]] {
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

    static func defaultEligibilityProposalValidator() -> EligibilityProposalValidator {
        return EligibilityProposalValidator(
            rules: [
                EligibilityProposalAllowedLabelRule(allowed: ["primary", "adaptive", "batched"]),
                EligibilityProposalRequiredLabelRule(message: "eligibility proposal needs this field"),
                EligibilityProposalCodeLengthRule(maxLength: 3600),
                EligibilityProposalLabelLengthRule(maxLength: 120),
                EligibilityProposalCodePrefixRule(prefix: "OPS"),
                EligibilityProposalDiagnosisCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
