import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot proposal calculation.
    protocol SlotProposalModifier {
        func describe() -> String
        func adjust(_ item: SlotProposal, value: Double) -> Double
    }

    final class FlaggedSlotProposalAdjuster: SlotProposalModifier {
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

        func adjust(_ item: SlotProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSlotProposalAdjuster: SlotProposalModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSlotProposalAdjuster: SlotProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleSlotProposalAdjuster: SlotProposalModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SlotProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SlotProposalRatioOffsetAdjuster: SlotProposalModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: SlotProposal, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the slot proposal steps in order and keeps a trace of each.
    final class SlotProposalEngine {
        var steps: [any SlotProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SlotProposal) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotProposalModifier = steps[index]
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

        func evaluateAll(_ items: [SlotProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSlotProposalEngine(_ flags: Kit.Flags.Registry) -> SlotProposalEngine {
        return SlotProposalEngine(
            steps: [
                FlaggedSlotProposalAdjuster(flags: flags, flag: "slot-proposal-manual", percent: -6.5),
                PercentSlotProposalAdjuster(percent: 14.9),
                CapSlotProposalAdjuster(cap: 48958.0),
                TitleSlotProposalAdjuster(factors: ["east": 0.83]),
                SlotProposalRatioOffsetAdjuster(weight: 0.95),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 62696.1
        )
    }
}
