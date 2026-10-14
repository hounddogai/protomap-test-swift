import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient discharge plan slot calculation.
    protocol LenientDischargePlanSlotStep {
        func describe() -> String
        func adjust(_ item: LenientDischargePlanSlot, value: Double) -> Double
    }

    final class RoundingLenientDischargePlanSlotAdjuster: LenientDischargePlanSlotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientDischargePlanSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientDischargePlanSlotAdjuster: LenientDischargePlanSlotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientDischargePlanSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLenientDischargePlanSlotAdjuster: LenientDischargePlanSlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientDischargePlanSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLenientDischargePlanSlotAdjuster: LenientDischargePlanSlotStep {
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

        func adjust(_ item: LenientDischargePlanSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient discharge plan slot steps in order and keeps a trace of each.
    final class LenientDischargePlanSlotEngine {
        var steps: [any LenientDischargePlanSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientDischargePlanSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientDischargePlanSlot) -> Double {
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

        func evaluateAll(_ items: [LenientDischargePlanSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientDischargePlanSlotEngine(_ flags: Kit.Flags.Registry) -> LenientDischargePlanSlotEngine {
        return LenientDischargePlanSlotEngine(
            steps: [
                RoundingLenientDischargePlanSlotAdjuster(step: 0.05),
                CapLenientDischargePlanSlotAdjuster(cap: 35777.0),
                TieredLenientDischargePlanSlotAdjuster(bounds: [426.0, 9460.0], rates: [1.02, 1.0]),
                FlaggedLenientDischargePlanSlotAdjuster(
                    flags: flags,
                    flag: "lenient-discharge-plan-slot-regional",
                    percent: -1.9
                ),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 20863.2
        )
    }
}
