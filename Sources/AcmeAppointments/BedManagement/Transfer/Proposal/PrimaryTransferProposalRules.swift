import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary transfer proposal must pass. Check returns its problems, or none.
    protocol PrimaryTransferProposalRule {
        func check(_ item: PrimaryTransferProposal) -> [String]
    }

    final class PrimaryTransferProposalRequiredDiagnosisCodeRule: PrimaryTransferProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTransferProposal) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTransferProposalSourceLengthRule: PrimaryTransferProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTransferProposal) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryTransferProposalNameLengthRule: PrimaryTransferProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryTransferProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryTransferProposalBatchSizeRangeRule: PrimaryTransferProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryTransferProposal) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryTransferProposalRequiredNameRule: PrimaryTransferProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTransferProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary transfer proposal.
    final class PrimaryTransferProposalValidator {
        var rules: [any PrimaryTransferProposalRule]

        init(rules: [any PrimaryTransferProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryTransferProposal) -> [String] {
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

        func requireValid(_ item: PrimaryTransferProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryTransferProposal]) -> [String: [String]] {
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

    static func defaultPrimaryTransferProposalValidator() -> PrimaryTransferProposalValidator {
        return PrimaryTransferProposalValidator(
            rules: [
                PrimaryTransferProposalRequiredDiagnosisCodeRule(message: "primary transfer proposal needs an entry"),
                PrimaryTransferProposalSourceLengthRule(maxLength: 3600),
                PrimaryTransferProposalNameLengthRule(maxLength: 1000),
                PrimaryTransferProposalBatchSizeRangeRule(min: 16, max: 120),
                PrimaryTransferProposalRequiredNameRule(message: "primary transfer proposal needs a value"),
            ]
        )
    }
}
