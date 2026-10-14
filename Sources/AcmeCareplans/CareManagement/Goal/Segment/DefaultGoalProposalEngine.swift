import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default goal proposal calculation.
    protocol DefaultGoalProposalAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultGoalProposal, value: Double) -> Double
    }

    final class TieredDefaultGoalProposalAdjuster: DefaultGoalProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultGoalProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryDefaultGoalProposalAdjuster: DefaultGoalProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: DefaultGoalProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DefaultGoalProposalCeilingOffsetAdjuster: DefaultGoalProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: DefaultGoalProposal, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class MinimumDefaultGoalProposalAdjuster: DefaultGoalProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultGoalProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultGoalProposalAdjuster: DefaultGoalProposalAdjuster {
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

        func adjust(_ item: DefaultGoalProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default goal proposal steps in order and keeps a trace of each.
    final class DefaultGoalProposalEngine {
        var steps: [any DefaultGoalProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultGoalProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultGoalProposal) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultGoalProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultGoalProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultGoalProposalEngine(_ flags: Kit.Flags.Registry) -> DefaultGoalProposalEngine {
        return DefaultGoalProposalEngine(
            steps: [
                TieredDefaultGoalProposalAdjuster(bounds: [2376.0, 2453.0, 9137.0], rates: [1.06, 1.12, 1.09]),
                CountryDefaultGoalProposalAdjuster(factors: ["east": 0.97, "west": 1.07]),
                DefaultGoalProposalCeilingOffsetAdjuster(weight: 0.79),
                MinimumDefaultGoalProposalAdjuster(minimum: 18.0),
                FlaggedDefaultGoalProposalAdjuster(flags: flags, flag: "default-goal-proposal-default", percent: 9.2),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 64252.1
        )
    }
}
