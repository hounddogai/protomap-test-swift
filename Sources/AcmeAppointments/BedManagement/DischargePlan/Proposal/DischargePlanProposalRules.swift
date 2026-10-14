import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan proposal must pass. Check returns its problems, or none.
    protocol DischargePlanProposalRule {
        func check(_ item: DischargePlanProposal) -> [String]
    }

    final class DischargePlanProposalCostRangeRule: DischargePlanProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanProposal) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanProposalLabelLengthRule: DischargePlanProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanProposalRequiredLabelRule: DischargePlanProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanProposalRequiredCodeRule: DischargePlanProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan proposal.
    final class DischargePlanProposalValidator {
        var rules: [any DischargePlanProposalRule]

        init(rules: [any DischargePlanProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanProposal) -> [String] {
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

        func requireValid(_ item: DischargePlanProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanProposal]) -> [String: [String]] {
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

    static func defaultDischargePlanProposalValidator() -> DischargePlanProposalValidator {
        return DischargePlanProposalValidator(
            rules: [
                DischargePlanProposalCostRangeRule(min: 9.2, max: 4587.8),
                DischargePlanProposalLabelLengthRule(maxLength: 80),
                DischargePlanProposalRequiredLabelRule(message: "discharge plan proposal needs a value"),
                DischargePlanProposalRequiredCodeRule(message: "discharge plan proposal needs a value"),
            ]
        )
    }
}
