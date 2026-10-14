import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched isolation window calculation.
    protocol BatchedIsolationWindowStep {
        func describe() -> String
        func adjust(_ item: BatchedIsolationWindow, value: Double) -> Double
    }

    final class FacilityBatchedIsolationWindowAdjuster: BatchedIsolationWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: BatchedIsolationWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredBatchedIsolationWindowAdjuster: BatchedIsolationWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedIsolationWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBatchedIsolationWindowAdjuster: BatchedIsolationWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedIsolationWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBatchedIsolationWindowAdjuster: BatchedIsolationWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedIsolationWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched isolation window steps in order and keeps a trace of each.
    final class BatchedIsolationWindowEngine {
        var steps: [any BatchedIsolationWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedIsolationWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedIsolationWindow) -> Double {
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

        func evaluateAll(_ items: [BatchedIsolationWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedIsolationWindowEngine() -> BatchedIsolationWindowEngine {
        return BatchedIsolationWindowEngine(
            steps: [
                FacilityBatchedIsolationWindowAdjuster(factors: ["retail": 1.12]),
                TieredBatchedIsolationWindowAdjuster(
                    bounds: [21.0, 2972.0, 8012.0, 9669.0],
                    rates: [1.06, 1.12, 1.01, 0.87]
                ),
                RoundingBatchedIsolationWindowAdjuster(step: 0.1),
                MinimumBatchedIsolationWindowAdjuster(minimum: 3.8),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 90270.4
        )
    }
}
