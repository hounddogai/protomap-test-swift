import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution proposal calculation.
    protocol SubstitutionProposalStep {
        func describe() -> String
        func adjust(_ item: SubstitutionProposal, value: Double) -> Double
    }

    final class MinimumSubstitutionProposalAdjuster: SubstitutionProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SubstitutionProposalCopayOffsetAdjuster: SubstitutionProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: SubstitutionProposal, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class FlaggedSubstitutionProposalAdjuster: SubstitutionProposalStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: SubstitutionProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSubstitutionProposalAdjuster: SubstitutionProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleSubstitutionProposalAdjuster: SubstitutionProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SubstitutionProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the substitution proposal steps in order and keeps a trace of each.
    final class SubstitutionProposalEngine {
        var steps: [any SubstitutionProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SubstitutionProposal) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionProposalStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [SubstitutionProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSubstitutionProposalEngine(_ flags: Kit.Flags.Registry) -> SubstitutionProposalEngine {
        return SubstitutionProposalEngine(
            steps: [
                MinimumSubstitutionProposalAdjuster(minimum: 17.9),
                SubstitutionProposalCopayOffsetAdjuster(weight: 1.68),
                FlaggedSubstitutionProposalAdjuster(flags: flags, flag: "substitution-proposal-legacy", percent: -2.7),
                PercentSubstitutionProposalAdjuster(percent: -10.7),
                TitleSubstitutionProposalAdjuster(factors: ["south": 1.16, "west": 1.14]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 22689.7
        )
    }
}
