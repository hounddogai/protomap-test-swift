import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task mapping calculation.
    protocol TaskMappingStep {
        func describe() -> String
        func adjust(_ item: TaskMapping, value: Double) -> Double
    }

    final class CapTaskMappingAdjuster: TaskMappingStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTaskMappingAdjuster: TaskMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTaskMappingAdjuster: TaskMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleTaskMappingAdjuster: TaskMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: TaskMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTaskMappingAdjuster: TaskMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TaskMappingRefillsOffsetAdjuster: TaskMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: TaskMapping, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    /// Runs the task mapping steps in order and keeps a trace of each.
    final class TaskMappingEngine {
        var steps: [any TaskMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TaskMapping) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskMappingStep = steps[index]
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

        func evaluateAll(_ items: [TaskMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTaskMappingEngine() -> TaskMappingEngine {
        return TaskMappingEngine(
            steps: [
                CapTaskMappingAdjuster(cap: 25017.0),
                MinimumTaskMappingAdjuster(minimum: 39.9),
                TieredTaskMappingAdjuster(bounds: [3951.0, 6159.0], rates: [1.06, 0.9]),
                LocaleTaskMappingAdjuster(factors: ["east": 1.26]),
                RoundingTaskMappingAdjuster(step: 0.25),
                TaskMappingRefillsOffsetAdjuster(weight: 0.54),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 97936.2
        )
    }
}
