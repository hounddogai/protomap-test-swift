import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted task schedule calculation.
    protocol WeightedTaskScheduleModifier {
        func describe() -> String
        func adjust(_ item: WeightedTaskSchedule, value: Double) -> Double
    }

    final class MinimumWeightedTaskScheduleAdjuster: WeightedTaskScheduleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedTaskSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedTaskScheduleAdjuster: WeightedTaskScheduleModifier {
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

        func adjust(_ item: WeightedTaskSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWeightedTaskScheduleAdjuster: WeightedTaskScheduleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedTaskSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted task schedule steps in order and keeps a trace of each.
    final class WeightedTaskScheduleEngine {
        var steps: [any WeightedTaskScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedTaskScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedTaskSchedule) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedTaskScheduleModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedTaskSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedTaskScheduleEngine(_ flags: Kit.Flags.Registry) -> WeightedTaskScheduleEngine {
        return WeightedTaskScheduleEngine(
            steps: [
                MinimumWeightedTaskScheduleAdjuster(minimum: 22.5),
                FlaggedWeightedTaskScheduleAdjuster(
                    flags: flags,
                    flag: "weighted-task-schedule-regional",
                    percent: -5.8
                ),
                RoundingWeightedTaskScheduleAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 4336.8
        )
    }
}
