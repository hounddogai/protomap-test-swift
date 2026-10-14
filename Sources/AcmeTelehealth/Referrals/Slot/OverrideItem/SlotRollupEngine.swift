import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot rollup calculation.
    protocol SlotRollupStep {
        func describe() -> String
        func adjust(_ item: SlotRollup, value: Double) -> Double
    }

    final class FlaggedSlotRollupAdjuster: SlotRollupStep {
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

        func adjust(_ item: SlotRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSlotRollupAdjuster: SlotRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SlotRollupRetriesOffsetAdjuster: SlotRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: SlotRollup, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class TieredSlotRollupAdjuster: SlotRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the slot rollup steps in order and keeps a trace of each.
    final class SlotRollupEngine {
        var steps: [any SlotRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SlotRollup) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [SlotRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSlotRollupEngine(_ flags: Kit.Flags.Registry) -> SlotRollupEngine {
        return SlotRollupEngine(
            steps: [
                FlaggedSlotRollupAdjuster(flags: flags, flag: "slot-rollup-capped", percent: -0.5),
                RoundingSlotRollupAdjuster(step: 1.0),
                SlotRollupRetriesOffsetAdjuster(weight: 0.33),
                TieredSlotRollupAdjuster(bounds: [4884.0, 5331.0, 5629.0], rates: [1.07, 0.93, 0.93]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 46171.7
        )
    }
}
