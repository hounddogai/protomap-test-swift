import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer proposal must pass. Check returns its problems, or none.
    protocol TransferProposalRule {
        func check(_ item: TransferProposal) -> [String]
    }

    final class TransferProposalFloorValueRangeRule: TransferProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferProposal) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferProposalSourceLengthRule: TransferProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferProposal) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferProposalBudgetRangeRule: TransferProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferProposal) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a transfer proposal.
    final class TransferProposalValidator {
        var rules: [any TransferProposalRule]

        init(rules: [any TransferProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferProposal]) -> [String: [String]] {
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

    static func defaultTransferProposalValidator() -> TransferProposalValidator {
        return TransferProposalValidator(
            rules: [
                TransferProposalFloorValueRangeRule(min: 5.7, max: 71.1),
                TransferProposalSourceLengthRule(maxLength: 16),
                TransferProposalBudgetRangeRule(min: 8.8, max: 2500.4),
            ]
        )
    }
}
