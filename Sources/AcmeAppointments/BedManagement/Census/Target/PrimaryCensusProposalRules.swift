import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary census proposal must pass. Check returns its problems, or none.
    protocol PrimaryCensusProposalRule {
        func check(_ item: PrimaryCensusProposal) -> [String]
    }

    final class PrimaryCensusProposalCodeLengthRule: PrimaryCensusProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCensusProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCensusProposalRequiredPatientRefRule: PrimaryCensusProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusProposal) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCensusProposalLimitRangeRule: PrimaryCensusProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCensusProposal) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryCensusProposalRequiredOwnerIDRule: PrimaryCensusProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusProposal) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary census proposal.
    final class PrimaryCensusProposalValidator {
        var rules: [any PrimaryCensusProposalRule]

        init(rules: [any PrimaryCensusProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCensusProposal) -> [String] {
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

        func requireValid(_ item: PrimaryCensusProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCensusProposal]) -> [String: [String]] {
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

    static func defaultPrimaryCensusProposalValidator() -> PrimaryCensusProposalValidator {
        return PrimaryCensusProposalValidator(
            rules: [
                PrimaryCensusProposalCodeLengthRule(maxLength: 120),
                PrimaryCensusProposalRequiredPatientRefRule(message: "primary census proposal needs a value"),
                PrimaryCensusProposalLimitRangeRule(min: 16, max: 1000),
                PrimaryCensusProposalRequiredOwnerIDRule(message: "primary census proposal needs an entry"),
            ]
        )
    }
}
