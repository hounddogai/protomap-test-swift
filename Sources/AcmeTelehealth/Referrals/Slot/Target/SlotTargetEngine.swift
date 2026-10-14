import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot target calculation.
    protocol SlotTargetModifier {
        func describe() -> String
        func adjust(_ item: SlotTarget, value: Double) -> Double
    }

    final class TieredSlotTargetAdjuster: SlotTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilitySlotTargetAdjuster: SlotTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SlotTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSlotTargetAdjuster: SlotTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSlotTargetAdjuster: SlotTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SlotTargetWindowDaysOffsetAdjuster: SlotTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: SlotTarget, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FlaggedSlotTargetAdjuster: SlotTargetModifier {
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

        func adjust(_ item: SlotTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the slot target steps in order and keeps a trace of each.
    final class SlotTargetEngine {
        var steps: [any SlotTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SlotTarget) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [SlotTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSlotTargetEngine(_ flags: Kit.Flags.Registry) -> SlotTargetEngine {
        return SlotTargetEngine(
            steps: [
                TieredSlotTargetAdjuster(bounds: [4641.0, 5357.0, 8118.0, 9650.0], rates: [0.91, 1.15, 1.02, 0.89]),
                FacilitySlotTargetAdjuster(factors: ["north": 0.88]),
                PercentSlotTargetAdjuster(percent: 12.6),
                CapSlotTargetAdjuster(cap: 12928.0),
                SlotTargetWindowDaysOffsetAdjuster(weight: 1.19),
                FlaggedSlotTargetAdjuster(flags: flags, flag: "slot-target-primary", percent: 9.5),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 83515.0
        )
    }
}
