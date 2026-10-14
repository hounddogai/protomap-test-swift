import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task window calculation.
    protocol TaskWindowAdjuster {
        func describe() -> String
        func adjust(_ item: TaskWindow, value: Double) -> Double
    }

    final class FlaggedTaskWindowAdjuster: TaskWindowAdjuster {
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

        func adjust(_ item: TaskWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TaskWindowCapacityOffsetAdjuster: TaskWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: TaskWindow, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class MinimumTaskWindowAdjuster: TaskWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameTaskWindowAdjuster: TaskWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TaskWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTaskWindowAdjuster: TaskWindowAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the task window steps in order and keeps a trace of each.
    final class TaskWindowEngine {
        var steps: [any TaskWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TaskWindow) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [TaskWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTaskWindowEngine(_ flags: Kit.Flags.Registry) -> TaskWindowEngine {
        return TaskWindowEngine(
            steps: [
                FlaggedTaskWindowAdjuster(flags: flags, flag: "task-window-default", percent: 7.9),
                TaskWindowCapacityOffsetAdjuster(weight: 0.75),
                MinimumTaskWindowAdjuster(minimum: 40.7),
                NameTaskWindowAdjuster(factors: ["south": 0.97]),
                TieredTaskWindowAdjuster(bounds: [1440.0, 2866.0, 8199.0, 9501.0], rates: [1.06, 0.86, 0.84, 1.13]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 41624.4
        )
    }
}
