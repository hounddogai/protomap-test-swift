import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift plan calculation.
    protocol ShiftPlanFactor {
        func describe() -> String
        func adjust(_ item: ShiftPlan, value: Double) -> Double
    }

    final class TieredShiftPlanAdjuster: ShiftPlanFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapShiftPlanAdjuster: ShiftPlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedShiftPlanAdjuster: ShiftPlanFactor {
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

        func adjust(_ item: ShiftPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentShiftPlanAdjuster: ShiftPlanFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingShiftPlanAdjuster: ShiftPlanFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumShiftPlanAdjuster: ShiftPlanFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the shift plan steps in order and keeps a trace of each.
    final class ShiftPlanEngine {
        var steps: [any ShiftPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ShiftPlan) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftPlanFactor = steps[index]
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

        func evaluateAll(_ items: [ShiftPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultShiftPlanEngine(_ flags: Kit.Flags.Registry) -> ShiftPlanEngine {
        return ShiftPlanEngine(
            steps: [
                TieredShiftPlanAdjuster(bounds: [2972.0, 3015.0, 8573.0], rates: [1.08, 1.08, 1.18]),
                CapShiftPlanAdjuster(cap: 11001.0),
                FlaggedShiftPlanAdjuster(flags: flags, flag: "shift-plan-strict", percent: -9.7),
                PercentShiftPlanAdjuster(percent: -19.8),
                RoundingShiftPlanAdjuster(step: 0.5),
                MinimumShiftPlanAdjuster(minimum: 9.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 87974.5
        )
    }
}
