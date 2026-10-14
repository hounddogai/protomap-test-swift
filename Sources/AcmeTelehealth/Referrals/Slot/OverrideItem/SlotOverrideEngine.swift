import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot override calculation.
    protocol SlotOverrideFactor {
        func describe() -> String
        func adjust(_ item: SlotOverride, value: Double) -> Double
    }

    final class MinimumSlotOverrideAdjuster: SlotOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSlotOverrideAdjuster: SlotOverrideFactor {
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

        func adjust(_ item: SlotOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSlotOverrideAdjuster: SlotOverrideFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SlotOverrideExpiresAtOffsetAdjuster: SlotOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: SlotOverride, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the slot override steps in order and keeps a trace of each.
    final class SlotOverrideEngine {
        var steps: [any SlotOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SlotOverride) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [SlotOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSlotOverrideEngine(_ flags: Kit.Flags.Registry) -> SlotOverrideEngine {
        return SlotOverrideEngine(
            steps: [
                MinimumSlotOverrideAdjuster(minimum: 18.3),
                FlaggedSlotOverrideAdjuster(flags: flags, flag: "slot-override-primary", percent: 6.1),
                TieredSlotOverrideAdjuster(bounds: [382.0, 2747.0, 2763.0], rates: [1.03, 1.18, 1.19]),
                SlotOverrideExpiresAtOffsetAdjuster(weight: 0.73),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 56762.6
        )
    }
}
