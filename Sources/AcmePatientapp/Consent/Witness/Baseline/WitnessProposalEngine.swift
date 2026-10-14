import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness proposal calculation.
    protocol WitnessProposalStep {
        func describe() -> String
        func adjust(_ item: WitnessProposal, value: Double) -> Double
    }

    final class CapWitnessProposalAdjuster: WitnessProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWitnessProposalAdjuster: WitnessProposalStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWitnessProposalAdjuster: WitnessProposalStep {
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

        func adjust(_ item: WitnessProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWitnessProposalAdjuster: WitnessProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWitnessProposalAdjuster: WitnessProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness proposal steps in order and keeps a trace of each.
    final class WitnessProposalEngine {
        var steps: [any WitnessProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WitnessProposal) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [WitnessProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWitnessProposalEngine(_ flags: Kit.Flags.Registry) -> WitnessProposalEngine {
        return WitnessProposalEngine(
            steps: [
                CapWitnessProposalAdjuster(cap: 8082.0),
                RoundingWitnessProposalAdjuster(step: 1.0),
                FlaggedWitnessProposalAdjuster(flags: flags, flag: "witness-proposal-lenient", percent: -9.5),
                MinimumWitnessProposalAdjuster(minimum: 8.7),
                PercentWitnessProposalAdjuster(percent: -22.6),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 12523.7
        )
    }
}
