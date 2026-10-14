import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task target calculation.
    protocol TaskTargetAdjuster {
        func describe() -> String
        func adjust(_ item: TaskTarget, value: Double) -> Double
    }

    final class TieredTaskTargetAdjuster: TaskTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TaskTargetFloorValueOffsetAdjuster: TaskTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: TaskTarget, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class FacilityTaskTargetAdjuster: TaskTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: TaskTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the task target steps in order and keeps a trace of each.
    final class TaskTargetEngine {
        var steps: [any TaskTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TaskTarget) -> Double {
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

        func evaluateAll(_ items: [TaskTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTaskTargetEngine() -> TaskTargetEngine {
        return TaskTargetEngine(
            steps: [
                TieredTaskTargetAdjuster(bounds: [1323.0, 1849.0], rates: [1.16, 1.17]),
                TaskTargetFloorValueOffsetAdjuster(weight: 1.57),
                FacilityTaskTargetAdjuster(factors: ["online": 0.77, "retail": 1.36]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 75016.7
        )
    }
}
