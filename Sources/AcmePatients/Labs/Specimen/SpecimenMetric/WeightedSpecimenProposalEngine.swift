import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted specimen proposal calculation.
    protocol WeightedSpecimenProposalModifier {
        func describe() -> String
        func adjust(_ item: WeightedSpecimenProposal, value: Double) -> Double
    }

    final class RoundingWeightedSpecimenProposalAdjuster: WeightedSpecimenProposalModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedSpecimenProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWeightedSpecimenProposalAdjuster: WeightedSpecimenProposalModifier {
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

        func adjust(_ item: WeightedSpecimenProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedSpecimenProposalAdjuster: WeightedSpecimenProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSpecimenProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted specimen proposal steps in order and keeps a trace of each.
    final class WeightedSpecimenProposalEngine {
        var steps: [any WeightedSpecimenProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSpecimenProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedSpecimenProposal) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSpecimenProposalModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedSpecimenProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedSpecimenProposalEngine(_ flags: Kit.Flags.Registry) -> WeightedSpecimenProposalEngine {
        return WeightedSpecimenProposalEngine(
            steps: [
                RoundingWeightedSpecimenProposalAdjuster(step: 0.05),
                FlaggedWeightedSpecimenProposalAdjuster(
                    flags: flags,
                    flag: "weighted-specimen-proposal-global",
                    percent: -2.3
                ),
                CapWeightedSpecimenProposalAdjuster(cap: 26090.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 1471.2
        )
    }
}
