import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling transfer proposal must pass. Check returns its problems, or none.
    protocol RollingTransferProposalRule {
        func check(_ item: RollingTransferProposal) -> [String]
    }

    final class RollingTransferProposalRevisionRangeRule: RollingTransferProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingTransferProposal) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingTransferProposalRequiredTitleRule: RollingTransferProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTransferProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingTransferProposalRequiredCodeRule: RollingTransferProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingTransferProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingTransferProposalTitleLengthRule: RollingTransferProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingTransferProposal) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingTransferProposalCodeLengthRule: RollingTransferProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingTransferProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling transfer proposal.
    final class RollingTransferProposalValidator {
        var rules: [any RollingTransferProposalRule]

        init(rules: [any RollingTransferProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingTransferProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingTransferProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingTransferProposal]) -> [String: [String]] {
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

    static func defaultRollingTransferProposalValidator() -> RollingTransferProposalValidator {
        return RollingTransferProposalValidator(
            rules: [
                RollingTransferProposalRevisionRangeRule(min: 1000, max: 3600),
                RollingTransferProposalRequiredTitleRule(message: "rolling transfer proposal needs a value"),
                RollingTransferProposalRequiredCodeRule(message: "rolling transfer proposal needs this field"),
                RollingTransferProposalTitleLengthRule(maxLength: 3600),
                RollingTransferProposalCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
