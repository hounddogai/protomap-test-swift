import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the scheduled shift group calculation.
    protocol ScheduledShiftGroupAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledShiftGroup, value: Double) -> Double
    }

    final class ScheduledShiftGroupCopayOffsetAdjuster: ScheduledShiftGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: ScheduledShiftGroup, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class FlaggedScheduledShiftGroupAdjuster: ScheduledShiftGroupAdjuster {
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

        func adjust(_ item: ScheduledShiftGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledShiftGroupAdjuster: ScheduledShiftGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledShiftGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentScheduledShiftGroupAdjuster: ScheduledShiftGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledShiftGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledShiftGroupAdjuster: ScheduledShiftGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledShiftGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledShiftGroupAdjuster: ScheduledShiftGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledShiftGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled shift group steps in order and keeps a trace of each.
    final class ScheduledShiftGroupEngine {
        var steps: [any ScheduledShiftGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledShiftGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledShiftGroup) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [ScheduledShiftGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledShiftGroupEngine(_ flags: Kit.Flags.Registry) -> ScheduledShiftGroupEngine {
        return ScheduledShiftGroupEngine(
            steps: [
                ScheduledShiftGroupCopayOffsetAdjuster(weight: 1.85),
                FlaggedScheduledShiftGroupAdjuster(flags: flags, flag: "scheduled-shift-group-capped", percent: 4.9),
                TieredScheduledShiftGroupAdjuster(bounds: [7368.0, 9458.0], rates: [0.82, 1.16]),
                PercentScheduledShiftGroupAdjuster(percent: -18.1),
                MinimumScheduledShiftGroupAdjuster(minimum: 0.9),
                CapScheduledShiftGroupAdjuster(cap: 38071.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 43799.5
        )
    }
}
