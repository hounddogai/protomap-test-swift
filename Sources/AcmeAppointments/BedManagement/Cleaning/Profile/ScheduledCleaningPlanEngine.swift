import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled cleaning plan calculation.
    protocol ScheduledCleaningPlanAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledCleaningPlan, value: Double) -> Double
    }

    final class TieredScheduledCleaningPlanAdjuster: ScheduledCleaningPlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCleaningPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumScheduledCleaningPlanAdjuster: ScheduledCleaningPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCleaningPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledCleaningPlanAdjuster: ScheduledCleaningPlanAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCleaningPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedScheduledCleaningPlanAdjuster: ScheduledCleaningPlanAdjuster {
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

        func adjust(_ item: ScheduledCleaningPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledCleaningPlanAdjuster: ScheduledCleaningPlanAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCleaningPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled cleaning plan steps in order and keeps a trace of each.
    final class ScheduledCleaningPlanEngine {
        var steps: [any ScheduledCleaningPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCleaningPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledCleaningPlan) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [ScheduledCleaningPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledCleaningPlanEngine(_ flags: Kit.Flags.Registry) -> ScheduledCleaningPlanEngine {
        return ScheduledCleaningPlanEngine(
            steps: [
                TieredScheduledCleaningPlanAdjuster(
                    bounds: [2001.0, 5383.0, 6432.0, 6996.0],
                    rates: [1.01, 1.0, 1.07, 0.98]
                ),
                MinimumScheduledCleaningPlanAdjuster(minimum: 29.1),
                PercentScheduledCleaningPlanAdjuster(percent: 20.9),
                FlaggedScheduledCleaningPlanAdjuster(
                    flags: flags,
                    flag: "scheduled-cleaning-plan-lenient",
                    percent: 5.5
                ),
                CapScheduledCleaningPlanAdjuster(cap: 1928.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 95813.0
        )
    }
}
