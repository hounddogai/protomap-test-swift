import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task cycle calculation.
    protocol TaskCycleAdjuster {
        func describe() -> String
        func adjust(_ item: TaskCycle, value: Double) -> Double
    }

    final class CapTaskCycleAdjuster: TaskCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceTaskCycleAdjuster: TaskCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: TaskCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTaskCycleAdjuster: TaskCycleAdjuster {
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

        func adjust(_ item: TaskCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TaskCycleAttemptsOffsetAdjuster: TaskCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: TaskCycle, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class RoundingTaskCycleAdjuster: TaskCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the task cycle steps in order and keeps a trace of each.
    final class TaskCycleEngine {
        var steps: [any TaskCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TaskCycle) -> Double {
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

        func evaluateAll(_ items: [TaskCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTaskCycleEngine(_ flags: Kit.Flags.Registry) -> TaskCycleEngine {
        return TaskCycleEngine(
            steps: [
                CapTaskCycleAdjuster(cap: 34618.0),
                SourceTaskCycleAdjuster(factors: ["south": 1.11, "north": 1.37, "central": 0.73]),
                FlaggedTaskCycleAdjuster(flags: flags, flag: "task-cycle-weighted", percent: -8.9),
                TaskCycleAttemptsOffsetAdjuster(weight: 1.95),
                RoundingTaskCycleAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 69148.9
        )
    }
}
