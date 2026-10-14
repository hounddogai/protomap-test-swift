import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot baseline calculation.
    protocol SlotBaselineFactor {
        func describe() -> String
        func adjust(_ item: SlotBaseline, value: Double) -> Double
    }

    final class RoundingSlotBaselineAdjuster: SlotBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardSlotBaselineAdjuster: SlotBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: SlotBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSlotBaselineAdjuster: SlotBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSlotBaselineAdjuster: SlotBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSlotBaselineAdjuster: SlotBaselineFactor {
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

        func adjust(_ item: SlotBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSlotBaselineAdjuster: SlotBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the slot baseline steps in order and keeps a trace of each.
    final class SlotBaselineEngine {
        var steps: [any SlotBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SlotBaseline) -> Double {
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

        func evaluateAll(_ items: [SlotBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSlotBaselineEngine(_ flags: Kit.Flags.Registry) -> SlotBaselineEngine {
        return SlotBaselineEngine(
            steps: [
                RoundingSlotBaselineAdjuster(step: 5.0),
                WardSlotBaselineAdjuster(factors: ["west": 1.07, "online": 1.33]),
                TieredSlotBaselineAdjuster(bounds: [4646.0, 5566.0, 8476.0, 8596.0], rates: [0.82, 1.18, 1.05, 1.04]),
                MinimumSlotBaselineAdjuster(minimum: 43.5),
                FlaggedSlotBaselineAdjuster(flags: flags, flag: "slot-baseline-batched", percent: 5.7),
                CapSlotBaselineAdjuster(cap: 2081.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 85691.0
        )
    }
}
