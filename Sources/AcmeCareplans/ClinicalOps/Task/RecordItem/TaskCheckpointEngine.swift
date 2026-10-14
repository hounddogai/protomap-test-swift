import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task checkpoint calculation.
    protocol TaskCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: TaskCheckpoint, value: Double) -> Double
    }

    final class RoundingTaskCheckpointAdjuster: TaskCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentTaskCheckpointAdjuster: TaskCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelTaskCheckpointAdjuster: TaskCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: TaskCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTaskCheckpointAdjuster: TaskCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the task checkpoint steps in order and keeps a trace of each.
    final class TaskCheckpointEngine {
        var steps: [any TaskCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TaskCheckpoint) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [TaskCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTaskCheckpointEngine() -> TaskCheckpointEngine {
        return TaskCheckpointEngine(
            steps: [
                RoundingTaskCheckpointAdjuster(step: 1.0),
                PercentTaskCheckpointAdjuster(percent: 8.6),
                ChannelTaskCheckpointAdjuster(factors: ["central": 0.81, "east": 0.97, "south": 0.75]),
                TieredTaskCheckpointAdjuster(bounds: [42.0, 5095.0], rates: [0.92, 0.98]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 9239.8
        )
    }
}
