import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan schedule calculation.
    protocol DischargePlanScheduleModifier {
        func describe() -> String
        func adjust(_ item: DischargePlanSchedule, value: Double) -> Double
    }

    final class RoundingDischargePlanScheduleAdjuster: DischargePlanScheduleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDischargePlanScheduleAdjuster: DischargePlanScheduleModifier {
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

        func adjust(_ item: DischargePlanSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDischargePlanScheduleAdjuster: DischargePlanScheduleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDischargePlanScheduleAdjuster: DischargePlanScheduleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDischargePlanScheduleAdjuster: DischargePlanScheduleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDischargePlanScheduleAdjuster: DischargePlanScheduleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the discharge plan schedule steps in order and keeps a trace of each.
    final class DischargePlanScheduleEngine {
        var steps: [any DischargePlanScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DischargePlanSchedule) -> Double {
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

        func evaluateAll(_ items: [DischargePlanSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDischargePlanScheduleEngine(_ flags: Kit.Flags.Registry) -> DischargePlanScheduleEngine {
        return DischargePlanScheduleEngine(
            steps: [
                RoundingDischargePlanScheduleAdjuster(step: 0.25),
                FlaggedDischargePlanScheduleAdjuster(
                    flags: flags,
                    flag: "discharge-plan-schedule-primary",
                    percent: 2.4
                ),
                PercentDischargePlanScheduleAdjuster(percent: -18.9),
                TieredDischargePlanScheduleAdjuster(
                    bounds: [2662.0, 4825.0, 6749.0, 7296.0],
                    rates: [0.99, 0.81, 0.99, 0.82]
                ),
                CapDischargePlanScheduleAdjuster(cap: 28420.0),
                MinimumDischargePlanScheduleAdjuster(minimum: 3.4),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 81439.2
        )
    }
}
