import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task allocation calculation.
    protocol TaskAllocationFactor {
        func describe() -> String
        func adjust(_ item: TaskAllocation, value: Double) -> Double
    }

    final class MinimumTaskAllocationAdjuster: TaskAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleTaskAllocationAdjuster: TaskAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: TaskAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTaskAllocationAdjuster: TaskAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapTaskAllocationAdjuster: TaskAllocationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the task allocation steps in order and keeps a trace of each.
    final class TaskAllocationEngine {
        var steps: [any TaskAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TaskAllocation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [TaskAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTaskAllocationEngine() -> TaskAllocationEngine {
        return TaskAllocationEngine(
            steps: [
                MinimumTaskAllocationAdjuster(minimum: 2.2),
                LocaleTaskAllocationAdjuster(factors: ["west": 1.35]),
                TieredTaskAllocationAdjuster(bounds: [5069.0, 6024.0, 6736.0], rates: [1.0, 1.02, 1.04]),
                CapTaskAllocationAdjuster(cap: 26952.0),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 13684.5
        )
    }
}
