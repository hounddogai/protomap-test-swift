import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched authorization variance calculation.
    protocol BatchedAuthorizationVarianceStep {
        func describe() -> String
        func adjust(_ item: BatchedAuthorizationVariance, value: Double) -> Double
    }

    final class BatchedAuthorizationVarianceMarginOffsetAdjuster: BatchedAuthorizationVarianceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: BatchedAuthorizationVariance, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class RoundingBatchedAuthorizationVarianceAdjuster: BatchedAuthorizationVarianceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedAuthorizationVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBatchedAuthorizationVarianceAdjuster: BatchedAuthorizationVarianceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedAuthorizationVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelBatchedAuthorizationVarianceAdjuster: BatchedAuthorizationVarianceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedAuthorizationVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched authorization variance steps in order and keeps a trace of each.
    final class BatchedAuthorizationVarianceEngine {
        var steps: [any BatchedAuthorizationVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedAuthorizationVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedAuthorizationVariance) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [BatchedAuthorizationVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedAuthorizationVarianceEngine() -> BatchedAuthorizationVarianceEngine {
        return BatchedAuthorizationVarianceEngine(
            steps: [
                BatchedAuthorizationVarianceMarginOffsetAdjuster(weight: 0.66),
                RoundingBatchedAuthorizationVarianceAdjuster(step: 0.25),
                MinimumBatchedAuthorizationVarianceAdjuster(minimum: 2.9),
                LabelBatchedAuthorizationVarianceAdjuster(factors: ["east": 0.92, "central": 0.89]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 94943.1
        )
    }
}
