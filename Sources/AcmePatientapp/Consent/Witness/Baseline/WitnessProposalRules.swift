import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness proposal must pass. Check returns its problems, or none.
    protocol WitnessProposalRule {
        func check(_ item: WitnessProposal) -> [String]
    }

    final class WitnessProposalRequiredTitleRule: WitnessProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessProposalClinicianIDLengthRule: WitnessProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessProposal) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessProposalRequiredCodeRule: WitnessProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessProposalCodePrefixRule: WitnessProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness proposal.
    final class WitnessProposalValidator {
        var rules: [any WitnessProposalRule]

        init(rules: [any WitnessProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessProposal]) -> [String: [String]] {
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

    static func defaultWitnessProposalValidator() -> WitnessProposalValidator {
        return WitnessProposalValidator(
            rules: [
                WitnessProposalRequiredTitleRule(message: "witness proposal needs this field"),
                WitnessProposalClinicianIDLengthRule(maxLength: 64),
                WitnessProposalRequiredCodeRule(message: "witness proposal needs an entry"),
                WitnessProposalCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
