import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge slot calculation.
    protocol ChargeSlotModifier {
        func describe() -> String
        func adjust(_ item: ChargeSlot, value: Double) -> Double
    }

    final class PercentChargeSlotAdjuster: ChargeSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingChargeSlotAdjuster: ChargeSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapChargeSlotAdjuster: ChargeSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedChargeSlotAdjuster: ChargeSlotModifier {
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

        func adjust(_ item: ChargeSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredChargeSlotAdjuster: ChargeSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChargeSlotRateOffsetAdjuster: ChargeSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ChargeSlot, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the charge slot steps in order and keeps a trace of each.
    final class ChargeSlotEngine {
        var steps: [any ChargeSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ChargeSlot) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeSlotModifier = steps[index]
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

        func evaluateAll(_ items: [ChargeSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultChargeSlotEngine(_ flags: Kit.Flags.Registry) -> ChargeSlotEngine {
        return ChargeSlotEngine(
            steps: [
                PercentChargeSlotAdjuster(percent: -15.8),
                RoundingChargeSlotAdjuster(step: 1.0),
                CapChargeSlotAdjuster(cap: 6062.0),
                FlaggedChargeSlotAdjuster(flags: flags, flag: "charge-slot-capped", percent: 2.8),
                TieredChargeSlotAdjuster(bounds: [2345.0, 2731.0, 5121.0], rates: [1.19, 0.84, 1.04]),
                ChargeSlotRateOffsetAdjuster(weight: 0.33),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 74568.9
        )
    }
}
