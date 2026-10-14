import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task group calculation.
    protocol TaskGroupStep {
        func describe() -> String
        func adjust(_ item: TaskGroup, value: Double) -> Double
    }

    final class TieredTaskGroupAdjuster: TaskGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleTaskGroupAdjuster: TaskGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TaskGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TaskGroupLimitOffsetAdjuster: TaskGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: TaskGroup, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class PercentTaskGroupAdjuster: TaskGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedTaskGroupAdjuster: TaskGroupStep {
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

        func adjust(_ item: TaskGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTaskGroupAdjuster: TaskGroupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the task group steps in order and keeps a trace of each.
    final class TaskGroupEngine {
        var steps: [any TaskGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TaskGroup) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskGroupStep = steps[index]
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

        func evaluateAll(_ items: [TaskGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTaskGroupEngine(_ flags: Kit.Flags.Registry) -> TaskGroupEngine {
        return TaskGroupEngine(
            steps: [
                TieredTaskGroupAdjuster(bounds: [3048.0, 3423.0, 4909.0, 7158.0], rates: [1.1, 0.98, 0.95, 0.88]),
                TitleTaskGroupAdjuster(factors: ["west": 0.91, "online": 1.06]),
                TaskGroupLimitOffsetAdjuster(weight: 0.97),
                PercentTaskGroupAdjuster(percent: -20.4),
                FlaggedTaskGroupAdjuster(flags: flags, flag: "task-group-rolling", percent: -8.9),
                MinimumTaskGroupAdjuster(minimum: 19.7),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 77674.3
        )
    }
}
