import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol proposal must pass. Check returns its problems, or none.
    protocol CareProtocolProposalRule {
        func check(_ item: CareProtocolProposal) -> [String]
    }

    final class CareProtocolProposalRequiredEncounterIDRule: CareProtocolProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolProposal) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolProposalCodeLengthRule: CareProtocolProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolProposalExpiresAtRangeRule: CareProtocolProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolProposal) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolProposalAllowedCodeRule: CareProtocolProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class CareProtocolProposalMarginRangeRule: CareProtocolProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolProposal) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolProposalEncounterIDLengthRule: CareProtocolProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolProposal) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol proposal.
    final class CareProtocolProposalValidator {
        var rules: [any CareProtocolProposalRule]

        init(rules: [any CareProtocolProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolProposal]) -> [String: [String]] {
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

    static func defaultCareProtocolProposalValidator() -> CareProtocolProposalValidator {
        return CareProtocolProposalValidator(
            rules: [
                CareProtocolProposalRequiredEncounterIDRule(message: "care protocol proposal needs this field"),
                CareProtocolProposalCodeLengthRule(maxLength: 255),
                CareProtocolProposalExpiresAtRangeRule(min: 120, max: 255),
                CareProtocolProposalAllowedCodeRule(allowed: ["rolling", "rolling", "regional"]),
                CareProtocolProposalMarginRangeRule(min: 3.2, max: 2247.7),
                CareProtocolProposalEncounterIDLengthRule(maxLength: 3600),
            ]
        )
    }
}
