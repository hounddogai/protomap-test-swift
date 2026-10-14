import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted read proposal must pass. Check returns its problems, or none.
    protocol WeightedReadProposalRule {
        func check(_ item: WeightedReadProposal) -> [String]
    }

    final class WeightedReadProposalRequiredLabelRule: WeightedReadProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReadProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReadProposalWeightRangeRule: WeightedReadProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReadProposal) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedReadProposalStartsAtRangeRule: WeightedReadProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReadProposal) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedReadProposalRateRangeRule: WeightedReadProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReadProposal) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedReadProposalSpecialtyLengthRule: WeightedReadProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReadProposal) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReadProposalRequiredSpecialtyRule: WeightedReadProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReadProposal) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted read proposal.
    final class WeightedReadProposalValidator {
        var rules: [any WeightedReadProposalRule]

        init(rules: [any WeightedReadProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReadProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedReadProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReadProposal]) -> [String: [String]] {
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

    static func defaultWeightedReadProposalValidator() -> WeightedReadProposalValidator {
        return WeightedReadProposalValidator(
            rules: [
                WeightedReadProposalRequiredLabelRule(message: "weighted read proposal needs this field"),
                WeightedReadProposalWeightRangeRule(min: 7.7, max: 2856.0),
                WeightedReadProposalStartsAtRangeRule(min: 32, max: 255),
                WeightedReadProposalRateRangeRule(min: 8.8, max: 673.2),
                WeightedReadProposalSpecialtyLengthRule(maxLength: 120),
                WeightedReadProposalRequiredSpecialtyRule(message: "weighted read proposal needs a value"),
            ]
        )
    }
}
