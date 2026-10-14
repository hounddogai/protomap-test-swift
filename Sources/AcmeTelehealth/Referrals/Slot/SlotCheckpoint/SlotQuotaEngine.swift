import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot quota calculation.
    protocol SlotQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: SlotQuota, value: Double) -> Double
    }

    final class CategorySlotQuotaAdjuster: SlotQuotaAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: SlotQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSlotQuotaAdjuster: SlotQuotaAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSlotQuotaAdjuster: SlotQuotaAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSlotQuotaAdjuster: SlotQuotaAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredSlotQuotaAdjuster: SlotQuotaAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSlotQuotaAdjuster: SlotQuotaAdjuster {
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

        func adjust(_ item: SlotQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the slot quota steps in order and keeps a trace of each.
    final class SlotQuotaEngine {
        var steps: [any SlotQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SlotQuota) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotQuotaAdjuster = steps[index]
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

        func evaluateAll(_ items: [SlotQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSlotQuotaEngine(_ flags: Kit.Flags.Registry) -> SlotQuotaEngine {
        return SlotQuotaEngine(
            steps: [
                CategorySlotQuotaAdjuster(factors: ["east": 1.13]),
                MinimumSlotQuotaAdjuster(minimum: 9.9),
                CapSlotQuotaAdjuster(cap: 29953.0),
                RoundingSlotQuotaAdjuster(step: 0.5),
                TieredSlotQuotaAdjuster(bounds: [1738.0, 3087.0], rates: [0.96, 0.84]),
                FlaggedSlotQuotaAdjuster(flags: flags, flag: "slot-quota-rolling", percent: -2.9),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 55788.1
        )
    }
}
