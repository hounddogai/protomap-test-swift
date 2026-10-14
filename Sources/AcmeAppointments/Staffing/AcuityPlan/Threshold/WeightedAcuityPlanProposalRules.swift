import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted acuity plan proposal must pass. Check returns its problems, or none.
    protocol WeightedAcuityPlanProposalRule {
        func check(_ item: WeightedAcuityPlanProposal) -> [String]
    }

    final class WeightedAcuityPlanProposalRequiredCodeRule: WeightedAcuityPlanProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAcuityPlanProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAcuityPlanProposalSequenceRangeRule: WeightedAcuityPlanProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedAcuityPlanProposal) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedAcuityPlanProposalActiveGuardRule: WeightedAcuityPlanProposalRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WeightedAcuityPlanProposal) -> [String] {
            if item.active && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted acuity plan proposal.
    final class WeightedAcuityPlanProposalValidator {
        var rules: [any WeightedAcuityPlanProposalRule]

        init(rules: [any WeightedAcuityPlanProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAcuityPlanProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedAcuityPlanProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAcuityPlanProposal]) -> [String: [String]] {
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

    static func defaultWeightedAcuityPlanProposalValidator() -> WeightedAcuityPlanProposalValidator {
        return WeightedAcuityPlanProposalValidator(
            rules: [
                WeightedAcuityPlanProposalRequiredCodeRule(message: "weighted acuity plan proposal needs an entry"),
                WeightedAcuityPlanProposalSequenceRangeRule(min: 1000, max: 3600),
                WeightedAcuityPlanProposalActiveGuardRule(limit: 0.8),
            ]
        )
    }
}
