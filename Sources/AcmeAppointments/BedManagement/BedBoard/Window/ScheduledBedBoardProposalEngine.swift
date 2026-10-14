import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled bed board proposal calculation.
    protocol ScheduledBedBoardProposalAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledBedBoardProposal, value: Double) -> Double
    }

    final class RoundingScheduledBedBoardProposalAdjuster: ScheduledBedBoardProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledBedBoardProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedScheduledBedBoardProposalAdjuster: ScheduledBedBoardProposalAdjuster {
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

        func adjust(_ item: ScheduledBedBoardProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelScheduledBedBoardProposalAdjuster: ScheduledBedBoardProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ScheduledBedBoardProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredScheduledBedBoardProposalAdjuster: ScheduledBedBoardProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledBedBoardProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledBedBoardProposalAdjuster: ScheduledBedBoardProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledBedBoardProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledBedBoardProposalAdjuster: ScheduledBedBoardProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledBedBoardProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled bed board proposal steps in order and keeps a trace of each.
    final class ScheduledBedBoardProposalEngine {
        var steps: [any ScheduledBedBoardProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledBedBoardProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledBedBoardProposal) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledBedBoardProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledBedBoardProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledBedBoardProposalEngine(_ flags: Kit.Flags.Registry) -> ScheduledBedBoardProposalEngine {
        return ScheduledBedBoardProposalEngine(
            steps: [
                RoundingScheduledBedBoardProposalAdjuster(step: 0.25),
                FlaggedScheduledBedBoardProposalAdjuster(
                    flags: flags,
                    flag: "scheduled-bed-board-proposal-global",
                    percent: -8.1
                ),
                LabelScheduledBedBoardProposalAdjuster(factors: ["west": 0.79]),
                TieredScheduledBedBoardProposalAdjuster(bounds: [7054.0, 9985.0], rates: [0.83, 1.05]),
                CapScheduledBedBoardProposalAdjuster(cap: 48009.0),
                MinimumScheduledBedBoardProposalAdjuster(minimum: 49.2),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 66654.3
        )
    }
}
