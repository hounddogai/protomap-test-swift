import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled care protocol schedule calculation.
    protocol ScheduledCareProtocolScheduleFactor {
        func describe() -> String
        func adjust(_ item: ScheduledCareProtocolSchedule, value: Double) -> Double
    }

    final class MinimumScheduledCareProtocolScheduleAdjuster: ScheduledCareProtocolScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCareProtocolSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ScheduledCareProtocolScheduleCopayOffsetAdjuster: ScheduledCareProtocolScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: ScheduledCareProtocolSchedule, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class FlaggedScheduledCareProtocolScheduleAdjuster: ScheduledCareProtocolScheduleFactor {
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

        func adjust(_ item: ScheduledCareProtocolSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledCareProtocolScheduleAdjuster: ScheduledCareProtocolScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCareProtocolSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled care protocol schedule steps in order and keeps a trace of each.
    final class ScheduledCareProtocolScheduleEngine {
        var steps: [any ScheduledCareProtocolScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareProtocolScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledCareProtocolSchedule) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledCareProtocolScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledCareProtocolSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledCareProtocolScheduleEngine(_ flags: Kit.Flags.Registry) -> ScheduledCareProtocolScheduleEngine {
        return ScheduledCareProtocolScheduleEngine(
            steps: [
                MinimumScheduledCareProtocolScheduleAdjuster(minimum: 11.9),
                ScheduledCareProtocolScheduleCopayOffsetAdjuster(weight: 1.8),
                FlaggedScheduledCareProtocolScheduleAdjuster(
                    flags: flags,
                    flag: "scheduled-care-protocol-schedule-tiered",
                    percent: 4.0
                ),
                CapScheduledCareProtocolScheduleAdjuster(cap: 16008.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 25566.6
        )
    }
}
