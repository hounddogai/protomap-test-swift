import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential proposal must pass. Check returns its problems, or none.
    protocol CredentialProposalRule {
        func check(_ item: CredentialProposal) -> [String]
    }

    final class CredentialProposalRequiredTitleRule: CredentialProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialProposalAllowedEncounterIDRule: CredentialProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is unknown"]
            }
            return []
        }
    }

    final class CredentialProposalRequiredEncounterIDRule: CredentialProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialProposal) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialProposalRequiredChecksumRule: CredentialProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialProposal) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialProposalArchivedGuardRule: CredentialProposalRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CredentialProposal) -> [String] {
            if item.archived && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class CredentialProposalCopayRangeRule: CredentialProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialProposal) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential proposal.
    final class CredentialProposalValidator {
        var rules: [any CredentialProposalRule]

        init(rules: [any CredentialProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialProposal]) -> [String: [String]] {
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

    static func defaultCredentialProposalValidator() -> CredentialProposalValidator {
        return CredentialProposalValidator(
            rules: [
                CredentialProposalRequiredTitleRule(message: "credential proposal needs a value"),
                CredentialProposalAllowedEncounterIDRule(allowed: ["lenient", "fallback", "tiered"]),
                CredentialProposalRequiredEncounterIDRule(message: "credential proposal needs a value"),
                CredentialProposalRequiredChecksumRule(message: "credential proposal needs a value"),
                CredentialProposalArchivedGuardRule(limit: 8.0),
                CredentialProposalCopayRangeRule(min: 3.9, max: 3672.2),
            ]
        )
    }
}
