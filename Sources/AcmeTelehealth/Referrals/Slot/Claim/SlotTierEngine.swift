import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot tier calculation.
    protocol SlotTierStep {
        func describe() -> String
        func adjust(_ item: SlotTier, value: Double) -> Double
    }

    final class MinimumSlotTierAdjuster: SlotTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSlotTierAdjuster: SlotTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSlotTierAdjuster: SlotTierStep {
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

        func adjust(_ item: SlotTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSlotTierAdjuster: SlotTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSlotTierAdjuster: SlotTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the slot tier steps in order and keeps a trace of each.
    final class SlotTierEngine {
        var steps: [any SlotTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SlotTier) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SlotTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSlotTierEngine(_ flags: Kit.Flags.Registry) -> SlotTierEngine {
        return SlotTierEngine(
            steps: [
                MinimumSlotTierAdjuster(minimum: 6.5),
                TieredSlotTierAdjuster(bounds: [4645.0, 6562.0, 7190.0, 8597.0], rates: [1.0, 0.88, 0.89, 0.96]),
                FlaggedSlotTierAdjuster(flags: flags, flag: "slot-tier-manual", percent: 9.5),
                PercentSlotTierAdjuster(percent: 18.0),
                RoundingSlotTierAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 65020.5
        )
    }
}
