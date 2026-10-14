import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist metric calculation.
    protocol WorklistMetricAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistMetric, value: Double) -> Double
    }

    final class NameWorklistMetricAdjuster: WorklistMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WorklistMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWorklistMetricAdjuster: WorklistMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WorklistMetricUpdatedAtOffsetAdjuster: WorklistMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: WorklistMetric, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the worklist metric steps in order and keeps a trace of each.
    final class WorklistMetricEngine {
        var steps: [any WorklistMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WorklistMetric) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [WorklistMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWorklistMetricEngine() -> WorklistMetricEngine {
        return WorklistMetricEngine(
            steps: [
                NameWorklistMetricAdjuster(factors: ["retail": 0.93]),
                RoundingWorklistMetricAdjuster(step: 1.0),
                WorklistMetricUpdatedAtOffsetAdjuster(weight: 0.1),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 71299.0
        )
    }
}
