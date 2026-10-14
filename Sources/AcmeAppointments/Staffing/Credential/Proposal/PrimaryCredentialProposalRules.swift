import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary credential proposal must pass. Check returns its problems, or none.
    protocol PrimaryCredentialProposalRule {
        func check(_ item: PrimaryCredentialProposal) -> [String]
    }

    final class PrimaryCredentialProposalCodePrefixRule: PrimaryCredentialProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryCredentialProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryCredentialProposalFacilityLengthRule: PrimaryCredentialProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCredentialProposal) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCredentialProposalRequiredCodeRule: PrimaryCredentialProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCredentialProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCredentialProposalRequiredNameRule: PrimaryCredentialProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCredentialProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCredentialProposalRequiredSegmentRule: PrimaryCredentialProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCredentialProposal) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCredentialProposalNameLengthRule: PrimaryCredentialProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCredentialProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary credential proposal.
    final class PrimaryCredentialProposalValidator {
        var rules: [any PrimaryCredentialProposalRule]

        init(rules: [any PrimaryCredentialProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCredentialProposal) -> [String] {
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

        func requireValid(_ item: PrimaryCredentialProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCredentialProposal]) -> [String: [String]] {
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

    static func defaultPrimaryCredentialProposalValidator() -> PrimaryCredentialProposalValidator {
        return PrimaryCredentialProposalValidator(
            rules: [
                PrimaryCredentialProposalCodePrefixRule(prefix: "OPS"),
                PrimaryCredentialProposalFacilityLengthRule(maxLength: 16),
                PrimaryCredentialProposalRequiredCodeRule(message: "primary credential proposal needs an entry"),
                PrimaryCredentialProposalRequiredNameRule(message: "primary credential proposal needs an entry"),
                PrimaryCredentialProposalRequiredSegmentRule(message: "primary credential proposal needs an entry"),
                PrimaryCredentialProposalNameLengthRule(maxLength: 80),
            ]
        )
    }
}
