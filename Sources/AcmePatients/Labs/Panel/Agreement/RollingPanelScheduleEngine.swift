import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling panel schedule calculation.
    protocol RollingPanelScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: RollingPanelSchedule, value: Double) -> Double
    }

    final class CapRollingPanelScheduleAdjuster: RollingPanelScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingPanelSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRollingPanelScheduleAdjuster: RollingPanelScheduleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingPanelSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRollingPanelScheduleAdjuster: RollingPanelScheduleAdjuster {
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

        func adjust(_ item: RollingPanelSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingPanelScheduleAdjuster: RollingPanelScheduleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingPanelSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRollingPanelScheduleAdjuster: RollingPanelScheduleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingPanelSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RollingPanelScheduleDosageMgOffsetAdjuster: RollingPanelScheduleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: RollingPanelSchedule, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the rolling panel schedule steps in order and keeps a trace of each.
    final class RollingPanelScheduleEngine {
        var steps: [any RollingPanelScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingPanelScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingPanelSchedule) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [RollingPanelSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingPanelScheduleEngine(_ flags: Kit.Flags.Registry) -> RollingPanelScheduleEngine {
        return RollingPanelScheduleEngine(
            steps: [
                CapRollingPanelScheduleAdjuster(cap: 4508.0),
                RoundingRollingPanelScheduleAdjuster(step: 0.25),
                FlaggedRollingPanelScheduleAdjuster(
                    flags: flags,
                    flag: "rolling-panel-schedule-seasonal",
                    percent: 9.7
                ),
                TieredRollingPanelScheduleAdjuster(bounds: [2263.0, 8049.0, 9965.0], rates: [1.15, 1.13, 1.0]),
                MinimumRollingPanelScheduleAdjuster(minimum: 33.2),
                RollingPanelScheduleDosageMgOffsetAdjuster(weight: 1.52),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 13215.2
        )
    }
}
