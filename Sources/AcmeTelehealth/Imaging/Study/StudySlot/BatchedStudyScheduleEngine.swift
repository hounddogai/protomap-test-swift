import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched study schedule calculation.
    protocol BatchedStudyScheduleStep {
        func describe() -> String
        func adjust(_ item: BatchedStudySchedule, value: Double) -> Double
    }

    final class MinimumBatchedStudyScheduleAdjuster: BatchedStudyScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedStudySchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedStudyScheduleAdjuster: BatchedStudyScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedStudySchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedBatchedStudyScheduleAdjuster: BatchedStudyScheduleStep {
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

        func adjust(_ item: BatchedStudySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedStudyScheduleAdjuster: BatchedStudyScheduleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedStudySchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the batched study schedule steps in order and keeps a trace of each.
    final class BatchedStudyScheduleEngine {
        var steps: [any BatchedStudyScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedStudyScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedStudySchedule) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedStudyScheduleStep = steps[index]
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

        func evaluateAll(_ items: [BatchedStudySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedStudyScheduleEngine(_ flags: Kit.Flags.Registry) -> BatchedStudyScheduleEngine {
        return BatchedStudyScheduleEngine(
            steps: [
                MinimumBatchedStudyScheduleAdjuster(minimum: 46.6),
                RoundingBatchedStudyScheduleAdjuster(step: 0.1),
                FlaggedBatchedStudyScheduleAdjuster(
                    flags: flags,
                    flag: "batched-study-schedule-seasonal",
                    percent: -2.9
                ),
                CapBatchedStudyScheduleAdjuster(cap: 37953.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 56818.1
        )
    }
}
