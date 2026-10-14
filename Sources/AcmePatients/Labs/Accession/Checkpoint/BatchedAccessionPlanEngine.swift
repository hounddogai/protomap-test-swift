import AcmePlatform
import Foundation

extension Labs {
    /// One step of the batched accession plan calculation.
    protocol BatchedAccessionPlanFactor {
        func describe() -> String
        func adjust(_ item: BatchedAccessionPlan, value: Double) -> Double
    }

    final class MinimumBatchedAccessionPlanAdjuster: BatchedAccessionPlanFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedAccessionPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedAccessionPlanAdjuster: BatchedAccessionPlanFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedAccessionPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BatchedAccessionPlanThresholdOffsetAdjuster: BatchedAccessionPlanFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: BatchedAccessionPlan, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the batched accession plan steps in order and keeps a trace of each.
    final class BatchedAccessionPlanEngine {
        var steps: [any BatchedAccessionPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedAccessionPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedAccessionPlan) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [BatchedAccessionPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedAccessionPlanEngine() -> BatchedAccessionPlanEngine {
        return BatchedAccessionPlanEngine(
            steps: [
                MinimumBatchedAccessionPlanAdjuster(minimum: 2.9),
                RoundingBatchedAccessionPlanAdjuster(step: 5.0),
                BatchedAccessionPlanThresholdOffsetAdjuster(weight: 0.49),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 54350.5
        )
    }
}
