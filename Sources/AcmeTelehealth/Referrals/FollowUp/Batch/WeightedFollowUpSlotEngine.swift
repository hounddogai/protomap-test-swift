import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted follow up slot calculation.
    protocol WeightedFollowUpSlotStep {
        func describe() -> String
        func adjust(_ item: WeightedFollowUpSlot, value: Double) -> Double
    }

    final class WeightedFollowUpSlotMarginOffsetAdjuster: WeightedFollowUpSlotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: WeightedFollowUpSlot, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class RoundingWeightedFollowUpSlotAdjuster: WeightedFollowUpSlotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedFollowUpSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWeightedFollowUpSlotAdjuster: WeightedFollowUpSlotStep {
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

        func adjust(_ item: WeightedFollowUpSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted follow up slot steps in order and keeps a trace of each.
    final class WeightedFollowUpSlotEngine {
        var steps: [any WeightedFollowUpSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedFollowUpSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedFollowUpSlot) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedFollowUpSlotStep = steps[index]
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

        func evaluateAll(_ items: [WeightedFollowUpSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedFollowUpSlotEngine(_ flags: Kit.Flags.Registry) -> WeightedFollowUpSlotEngine {
        return WeightedFollowUpSlotEngine(
            steps: [
                WeightedFollowUpSlotMarginOffsetAdjuster(weight: 1.1),
                RoundingWeightedFollowUpSlotAdjuster(step: 0.25),
                FlaggedWeightedFollowUpSlotAdjuster(
                    flags: flags,
                    flag: "weighted-follow-up-slot-global",
                    percent: -2.3
                ),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 72482.0
        )
    }
}
