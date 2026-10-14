import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default interaction schedule calculation.
    protocol DefaultInteractionScheduleStep {
        func describe() -> String
        func adjust(_ item: DefaultInteractionSchedule, value: Double) -> Double
    }

    final class PercentDefaultInteractionScheduleAdjuster: DefaultInteractionScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultInteractionSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultInteractionScheduleAdjuster: DefaultInteractionScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultInteractionSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultInteractionScheduleAdjuster: DefaultInteractionScheduleStep {
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

        func adjust(_ item: DefaultInteractionSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultInteractionScheduleAdjuster: DefaultInteractionScheduleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultInteractionSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DefaultInteractionScheduleCapacityOffsetAdjuster: DefaultInteractionScheduleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: DefaultInteractionSchedule, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the default interaction schedule steps in order and keeps a trace of each.
    final class DefaultInteractionScheduleEngine {
        var steps: [any DefaultInteractionScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultInteractionScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultInteractionSchedule) -> Double {
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

        func evaluateAll(_ items: [DefaultInteractionSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultInteractionScheduleEngine(_ flags: Kit.Flags.Registry) -> DefaultInteractionScheduleEngine {
        return DefaultInteractionScheduleEngine(
            steps: [
                PercentDefaultInteractionScheduleAdjuster(percent: 3.0),
                MinimumDefaultInteractionScheduleAdjuster(minimum: 41.2),
                FlaggedDefaultInteractionScheduleAdjuster(
                    flags: flags,
                    flag: "default-interaction-schedule-seasonal",
                    percent: -9.6
                ),
                CapDefaultInteractionScheduleAdjuster(cap: 24850.0),
                DefaultInteractionScheduleCapacityOffsetAdjuster(weight: 0.41),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 22642.1
        )
    }
}
