import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling transfer proposal calculation.
    protocol RollingTransferProposalStep {
        func describe() -> String
        func adjust(_ item: RollingTransferProposal, value: Double) -> Double
    }

    final class RoundingRollingTransferProposalAdjuster: RollingTransferProposalStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingTransferProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRollingTransferProposalAdjuster: RollingTransferProposalStep {
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

        func adjust(_ item: RollingTransferProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingTransferProposalAttemptsOffsetAdjuster: RollingTransferProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: RollingTransferProposal, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class ChannelRollingTransferProposalAdjuster: RollingTransferProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RollingTransferProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRollingTransferProposalAdjuster: RollingTransferProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingTransferProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling transfer proposal steps in order and keeps a trace of each.
    final class RollingTransferProposalEngine {
        var steps: [any RollingTransferProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingTransferProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingTransferProposal) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [RollingTransferProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingTransferProposalEngine(_ flags: Kit.Flags.Registry) -> RollingTransferProposalEngine {
        return RollingTransferProposalEngine(
            steps: [
                RoundingRollingTransferProposalAdjuster(step: 0.05),
                FlaggedRollingTransferProposalAdjuster(
                    flags: flags,
                    flag: "rolling-transfer-proposal-primary",
                    percent: -5.2
                ),
                RollingTransferProposalAttemptsOffsetAdjuster(weight: 0.36),
                ChannelRollingTransferProposalAdjuster(factors: ["west": 1.2]),
                CapRollingTransferProposalAdjuster(cap: 36807.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 66976.1
        )
    }
}
