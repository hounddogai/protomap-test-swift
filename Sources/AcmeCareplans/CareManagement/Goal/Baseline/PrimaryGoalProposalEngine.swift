import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary goal proposal calculation.
    protocol PrimaryGoalProposalAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryGoalProposal, value: Double) -> Double
    }

    final class LabelPrimaryGoalProposalAdjuster: PrimaryGoalProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryGoalProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimaryGoalProposalAdjuster: PrimaryGoalProposalAdjuster {
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

        func adjust(_ item: PrimaryGoalProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPrimaryGoalProposalAdjuster: PrimaryGoalProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryGoalProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryGoalProposalAdjuster: PrimaryGoalProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryGoalProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryGoalProposalAdjuster: PrimaryGoalProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryGoalProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary goal proposal steps in order and keeps a trace of each.
    final class PrimaryGoalProposalEngine {
        var steps: [any PrimaryGoalProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryGoalProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryGoalProposal) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PrimaryGoalProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryGoalProposalEngine(_ flags: Kit.Flags.Registry) -> PrimaryGoalProposalEngine {
        return PrimaryGoalProposalEngine(
            steps: [
                LabelPrimaryGoalProposalAdjuster(factors: ["west": 1.14]),
                FlaggedPrimaryGoalProposalAdjuster(flags: flags, flag: "primary-goal-proposal-primary", percent: 0.9),
                PercentPrimaryGoalProposalAdjuster(percent: 12.6),
                RoundingPrimaryGoalProposalAdjuster(step: 1.0),
                MinimumPrimaryGoalProposalAdjuster(minimum: 29.5),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 80048.6
        )
    }
}
