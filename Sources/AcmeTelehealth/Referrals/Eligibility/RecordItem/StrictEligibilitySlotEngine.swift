import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the strict eligibility slot calculation.
    protocol StrictEligibilitySlotModifier {
        func describe() -> String
        func adjust(_ item: StrictEligibilitySlot, value: Double) -> Double
    }

    final class StrictEligibilitySlotQuantityOffsetAdjuster: StrictEligibilitySlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: StrictEligibilitySlot, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class RoundingStrictEligibilitySlotAdjuster: StrictEligibilitySlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictEligibilitySlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameStrictEligibilitySlotAdjuster: StrictEligibilitySlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictEligibilitySlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStrictEligibilitySlotAdjuster: StrictEligibilitySlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictEligibilitySlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumStrictEligibilitySlotAdjuster: StrictEligibilitySlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictEligibilitySlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStrictEligibilitySlotAdjuster: StrictEligibilitySlotModifier {
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

        func adjust(_ item: StrictEligibilitySlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict eligibility slot steps in order and keeps a trace of each.
    final class StrictEligibilitySlotEngine {
        var steps: [any StrictEligibilitySlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictEligibilitySlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictEligibilitySlot) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [StrictEligibilitySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictEligibilitySlotEngine(_ flags: Kit.Flags.Registry) -> StrictEligibilitySlotEngine {
        return StrictEligibilitySlotEngine(
            steps: [
                StrictEligibilitySlotQuantityOffsetAdjuster(weight: 0.81),
                RoundingStrictEligibilitySlotAdjuster(step: 0.25),
                NameStrictEligibilitySlotAdjuster(factors: ["online": 1.35, "east": 1.3]),
                CapStrictEligibilitySlotAdjuster(cap: 37894.0),
                MinimumStrictEligibilitySlotAdjuster(minimum: 38.8),
                FlaggedStrictEligibilitySlotAdjuster(
                    flags: flags,
                    flag: "strict-eligibility-slot-tiered",
                    percent: 5.4
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 67495.4
        )
    }
}
