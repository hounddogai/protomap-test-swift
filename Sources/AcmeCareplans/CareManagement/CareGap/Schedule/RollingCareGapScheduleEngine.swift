import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling care gap schedule calculation.
    protocol RollingCareGapScheduleStep {
        func describe() -> String
        func adjust(_ item: RollingCareGapSchedule, value: Double) -> Double
    }

    final class FlaggedRollingCareGapScheduleAdjuster: RollingCareGapScheduleStep {
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

        func adjust(_ item: RollingCareGapSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingCareGapScheduleCapacityOffsetAdjuster: RollingCareGapScheduleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RollingCareGapSchedule, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TitleRollingCareGapScheduleAdjuster: RollingCareGapScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RollingCareGapSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingCareGapScheduleAdjuster: RollingCareGapScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingCareGapSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRollingCareGapScheduleAdjuster: RollingCareGapScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingCareGapSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRollingCareGapScheduleAdjuster: RollingCareGapScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingCareGapSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling care gap schedule steps in order and keeps a trace of each.
    final class RollingCareGapScheduleEngine {
        var steps: [any RollingCareGapScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCareGapScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingCareGapSchedule) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingCareGapScheduleStep = steps[index]
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

        func evaluateAll(_ items: [RollingCareGapSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingCareGapScheduleEngine(_ flags: Kit.Flags.Registry) -> RollingCareGapScheduleEngine {
        return RollingCareGapScheduleEngine(
            steps: [
                FlaggedRollingCareGapScheduleAdjuster(
                    flags: flags,
                    flag: "rolling-care-gap-schedule-primary",
                    percent: -0.2
                ),
                RollingCareGapScheduleCapacityOffsetAdjuster(weight: 1.48),
                TitleRollingCareGapScheduleAdjuster(factors: ["south": 1.01]),
                TieredRollingCareGapScheduleAdjuster(
                    bounds: [1127.0, 3443.0, 5107.0, 8070.0],
                    rates: [1.1, 1.01, 1.08, 0.84]
                ),
                PercentRollingCareGapScheduleAdjuster(percent: -20.0),
                MinimumRollingCareGapScheduleAdjuster(minimum: 5.9),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 72357.7
        )
    }
}
