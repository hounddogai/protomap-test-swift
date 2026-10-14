import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census proposal must pass. Check returns its problems, or none.
    protocol CensusProposalRule {
        func check(_ item: CensusProposal) -> [String]
    }

    final class CensusProposalCountryLengthRule: CensusProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusProposal) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusProposalCodeLengthRule: CensusProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusProposalRequiredWardRule: CensusProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusProposal) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusProposalWardLengthRule: CensusProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusProposal) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusProposalAllowedWardRule: CensusProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is too long"]
            }
            return []
        }
    }

    final class CensusProposalRequiredTitleRule: CensusProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census proposal.
    final class CensusProposalValidator {
        var rules: [any CensusProposalRule]

        init(rules: [any CensusProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusProposal]) -> [String: [String]] {
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

    static func defaultCensusProposalValidator() -> CensusProposalValidator {
        return CensusProposalValidator(
            rules: [
                CensusProposalCountryLengthRule(maxLength: 1000),
                CensusProposalCodeLengthRule(maxLength: 32),
                CensusProposalRequiredWardRule(message: "census proposal needs a value"),
                CensusProposalWardLengthRule(maxLength: 120),
                CensusProposalAllowedWardRule(allowed: ["batched", "regional"]),
                CensusProposalRequiredTitleRule(message: "census proposal needs a value"),
            ]
        )
    }
}
