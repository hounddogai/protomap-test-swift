import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending recall proposal must pass. Check returns its problems, or none.
    protocol PendingRecallProposalRule {
        func check(_ item: PendingRecallProposal) -> [String]
    }

    final class PendingRecallProposalTitleLengthRule: PendingRecallProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRecallProposal) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRecallProposalRequiredCodeRule: PendingRecallProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRecallProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRecallProposalMarginRangeRule: PendingRecallProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRecallProposal) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingRecallProposalRequiredTitleRule: PendingRecallProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRecallProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRecallProposalCapacityRangeRule: PendingRecallProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRecallProposal) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingRecallProposalDiscountRangeRule: PendingRecallProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRecallProposal) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending recall proposal.
    final class PendingRecallProposalValidator {
        var rules: [any PendingRecallProposalRule]

        init(rules: [any PendingRecallProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRecallProposal) -> [String] {
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

        func requireValid(_ item: PendingRecallProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRecallProposal]) -> [String: [String]] {
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

    static func defaultPendingRecallProposalValidator() -> PendingRecallProposalValidator {
        return PendingRecallProposalValidator(
            rules: [
                PendingRecallProposalTitleLengthRule(maxLength: 64),
                PendingRecallProposalRequiredCodeRule(message: "pending recall proposal needs a value"),
                PendingRecallProposalMarginRangeRule(min: 4.0, max: 2472.2),
                PendingRecallProposalRequiredTitleRule(message: "pending recall proposal needs this field"),
                PendingRecallProposalCapacityRangeRule(min: 120, max: 255),
                PendingRecallProposalDiscountRangeRule(min: 6.8, max: 2353.6),
            ]
        )
    }
}
