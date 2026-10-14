import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task plan calculation.
    protocol TaskPlanAdjuster {
        func describe() -> String
        func adjust(_ item: TaskPlan, value: Double) -> Double
    }

    final class TieredTaskPlanAdjuster: TaskPlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTaskPlanAdjuster: TaskPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTaskPlanAdjuster: TaskPlanAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelTaskPlanAdjuster: TaskPlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TaskPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the task plan steps in order and keeps a trace of each.
    final class TaskPlanEngine {
        var steps: [any TaskPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TaskPlan) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskPlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [TaskPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTaskPlanEngine() -> TaskPlanEngine {
        return TaskPlanEngine(
            steps: [
                TieredTaskPlanAdjuster(bounds: [2565.0, 8285.0], rates: [0.84, 1.11]),
                MinimumTaskPlanAdjuster(minimum: 15.4),
                CapTaskPlanAdjuster(cap: 27280.0),
                LabelTaskPlanAdjuster(factors: ["central": 1.29, "online": 1.09]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 36821.4
        )
    }
}
