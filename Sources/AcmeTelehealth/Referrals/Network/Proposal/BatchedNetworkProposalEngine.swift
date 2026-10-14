import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched network proposal calculation.
    protocol BatchedNetworkProposalStep {
        func describe() -> String
        func adjust(_ item: BatchedNetworkProposal, value: Double) -> Double
    }

    final class RoundingBatchedNetworkProposalAdjuster: BatchedNetworkProposalStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedNetworkProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredBatchedNetworkProposalAdjuster: BatchedNetworkProposalStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedNetworkProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BatchedNetworkProposalCopayOffsetAdjuster: BatchedNetworkProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: BatchedNetworkProposal, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class CapBatchedNetworkProposalAdjuster: BatchedNetworkProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedNetworkProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedNetworkProposalAdjuster: BatchedNetworkProposalStep {
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

        func adjust(_ item: BatchedNetworkProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedNetworkProposalAdjuster: BatchedNetworkProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedNetworkProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched network proposal steps in order and keeps a trace of each.
    final class BatchedNetworkProposalEngine {
        var steps: [any BatchedNetworkProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedNetworkProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedNetworkProposal) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedNetworkProposalStep = steps[index]
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

        func evaluateAll(_ items: [BatchedNetworkProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedNetworkProposalEngine(_ flags: Kit.Flags.Registry) -> BatchedNetworkProposalEngine {
        return BatchedNetworkProposalEngine(
            steps: [
                RoundingBatchedNetworkProposalAdjuster(step: 0.05),
                TieredBatchedNetworkProposalAdjuster(bounds: [3377.0, 4262.0], rates: [1.1, 1.12]),
                BatchedNetworkProposalCopayOffsetAdjuster(weight: 1.32),
                CapBatchedNetworkProposalAdjuster(cap: 29143.0),
                FlaggedBatchedNetworkProposalAdjuster(
                    flags: flags,
                    flag: "batched-network-proposal-fallback",
                    percent: -1.1
                ),
                MinimumBatchedNetworkProposalAdjuster(minimum: 15.4),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 54554.5
        )
    }
}
