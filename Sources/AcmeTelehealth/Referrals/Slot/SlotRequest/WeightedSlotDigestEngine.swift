import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted slot digest calculation.
    protocol WeightedSlotDigestAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedSlotDigest, value: Double) -> Double
    }

    final class RoundingWeightedSlotDigestAdjuster: WeightedSlotDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedSlotDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedSlotDigestAdjuster: WeightedSlotDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSlotDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentWeightedSlotDigestAdjuster: WeightedSlotDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedSlotDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWeightedSlotDigestAdjuster: WeightedSlotDigestAdjuster {
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

        func adjust(_ item: WeightedSlotDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted slot digest steps in order and keeps a trace of each.
    final class WeightedSlotDigestEngine {
        var steps: [any WeightedSlotDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSlotDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedSlotDigest) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSlotDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedSlotDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedSlotDigestEngine(_ flags: Kit.Flags.Registry) -> WeightedSlotDigestEngine {
        return WeightedSlotDigestEngine(
            steps: [
                RoundingWeightedSlotDigestAdjuster(step: 1.0),
                CapWeightedSlotDigestAdjuster(cap: 9879.0),
                PercentWeightedSlotDigestAdjuster(percent: -13.1),
                FlaggedWeightedSlotDigestAdjuster(flags: flags, flag: "weighted-slot-digest-regional", percent: -1.5),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 17267.7
        )
    }
}
