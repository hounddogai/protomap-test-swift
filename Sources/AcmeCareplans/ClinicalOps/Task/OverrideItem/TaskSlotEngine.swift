import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task slot calculation.
    protocol TaskSlotStep {
        func describe() -> String
        func adjust(_ item: TaskSlot, value: Double) -> Double
    }

    final class PercentTaskSlotAdjuster: TaskSlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTaskSlotAdjuster: TaskSlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameTaskSlotAdjuster: TaskSlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TaskSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the task slot steps in order and keeps a trace of each.
    final class TaskSlotEngine {
        var steps: [any TaskSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TaskSlot) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskSlotStep = steps[index]
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

        func evaluateAll(_ items: [TaskSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTaskSlotEngine() -> TaskSlotEngine {
        return TaskSlotEngine(
            steps: [
                PercentTaskSlotAdjuster(percent: 7.6),
                TieredTaskSlotAdjuster(bounds: [1675.0, 8349.0, 9321.0], rates: [1.08, 0.81, 0.85]),
                NameTaskSlotAdjuster(factors: ["central": 0.81, "east": 0.97]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 51442.1
        )
    }
}
