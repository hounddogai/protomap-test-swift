import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim proposal calculation.
    protocol ClaimProposalFactor {
        func describe() -> String
        func adjust(_ item: ClaimProposal, value: Double) -> Double
    }

    final class ClaimProposalEndsAtOffsetAdjuster: ClaimProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ClaimProposal, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class CapClaimProposalAdjuster: ClaimProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentClaimProposalAdjuster: ClaimProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedClaimProposalAdjuster: ClaimProposalFactor {
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

        func adjust(_ item: ClaimProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameClaimProposalAdjuster: ClaimProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ClaimProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingClaimProposalAdjuster: ClaimProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the claim proposal steps in order and keeps a trace of each.
    final class ClaimProposalEngine {
        var steps: [any ClaimProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimProposal) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [ClaimProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimProposalEngine(_ flags: Kit.Flags.Registry) -> ClaimProposalEngine {
        return ClaimProposalEngine(
            steps: [
                ClaimProposalEndsAtOffsetAdjuster(weight: 0.43),
                CapClaimProposalAdjuster(cap: 49787.0),
                PercentClaimProposalAdjuster(percent: -0.7),
                FlaggedClaimProposalAdjuster(flags: flags, flag: "claim-proposal-global", percent: 5.6),
                NameClaimProposalAdjuster(factors: ["online": 1.11]),
                RoundingClaimProposalAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 22145.7
        )
    }
}
