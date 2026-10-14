import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient acuity plan slot calculation.
    protocol LenientAcuityPlanSlotStep {
        func describe() -> String
        func adjust(_ item: LenientAcuityPlanSlot, value: Double) -> Double
    }

    final class LenientAcuityPlanSlotQuantityOffsetAdjuster: LenientAcuityPlanSlotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: LenientAcuityPlanSlot, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredLenientAcuityPlanSlotAdjuster: LenientAcuityPlanSlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientAcuityPlanSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLenientAcuityPlanSlotAdjuster: LenientAcuityPlanSlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientAcuityPlanSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientAcuityPlanSlotAdjuster: LenientAcuityPlanSlotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientAcuityPlanSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientAcuityPlanSlotAdjuster: LenientAcuityPlanSlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientAcuityPlanSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLenientAcuityPlanSlotAdjuster: LenientAcuityPlanSlotStep {
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

        func adjust(_ item: LenientAcuityPlanSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient acuity plan slot steps in order and keeps a trace of each.
    final class LenientAcuityPlanSlotEngine {
        var steps: [any LenientAcuityPlanSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAcuityPlanSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientAcuityPlanSlot) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [LenientAcuityPlanSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientAcuityPlanSlotEngine(_ flags: Kit.Flags.Registry) -> LenientAcuityPlanSlotEngine {
        return LenientAcuityPlanSlotEngine(
            steps: [
                LenientAcuityPlanSlotQuantityOffsetAdjuster(weight: 1.29),
                TieredLenientAcuityPlanSlotAdjuster(bounds: [2527.0, 3784.0, 5255.0], rates: [1.19, 0.98, 1.18]),
                MinimumLenientAcuityPlanSlotAdjuster(minimum: 24.9),
                CapLenientAcuityPlanSlotAdjuster(cap: 38977.0),
                PercentLenientAcuityPlanSlotAdjuster(percent: -24.3),
                FlaggedLenientAcuityPlanSlotAdjuster(
                    flags: flags,
                    flag: "lenient-acuity-plan-slot-strict",
                    percent: -3.2
                ),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 67670.7
        )
    }
}
