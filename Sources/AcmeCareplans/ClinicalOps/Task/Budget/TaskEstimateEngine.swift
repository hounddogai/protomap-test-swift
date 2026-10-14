import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task estimate calculation.
    protocol TaskEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: TaskEstimate, value: Double) -> Double
    }

    final class TieredTaskEstimateAdjuster: TaskEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapTaskEstimateAdjuster: TaskEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryTaskEstimateAdjuster: TaskEstimateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: TaskEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTaskEstimateAdjuster: TaskEstimateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingTaskEstimateAdjuster: TaskEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the task estimate steps in order and keeps a trace of each.
    final class TaskEstimateEngine {
        var steps: [any TaskEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TaskEstimate) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [TaskEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTaskEstimateEngine() -> TaskEstimateEngine {
        return TaskEstimateEngine(
            steps: [
                TieredTaskEstimateAdjuster(bounds: [674.0, 1465.0, 2120.0, 9653.0], rates: [1.2, 1.17, 1.03, 1.09]),
                CapTaskEstimateAdjuster(cap: 36101.0),
                CategoryTaskEstimateAdjuster(factors: ["east": 0.8]),
                MinimumTaskEstimateAdjuster(minimum: 48.1),
                RoundingTaskEstimateAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 84879.6
        )
    }
}
