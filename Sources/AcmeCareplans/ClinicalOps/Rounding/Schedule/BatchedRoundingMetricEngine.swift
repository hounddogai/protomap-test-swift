import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched rounding metric calculation.
    protocol BatchedRoundingMetricFactor {
        func describe() -> String
        func adjust(_ item: BatchedRoundingMetric, value: Double) -> Double
    }

    final class CapBatchedRoundingMetricAdjuster: BatchedRoundingMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedRoundingMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedRoundingMetricAdjuster: BatchedRoundingMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRoundingMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedRoundingMetricAdjuster: BatchedRoundingMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedRoundingMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched rounding metric steps in order and keeps a trace of each.
    final class BatchedRoundingMetricEngine {
        var steps: [any BatchedRoundingMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRoundingMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedRoundingMetric) -> Double {
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

        func evaluateAll(_ items: [BatchedRoundingMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedRoundingMetricEngine() -> BatchedRoundingMetricEngine {
        return BatchedRoundingMetricEngine(
            steps: [
                CapBatchedRoundingMetricAdjuster(cap: 20356.0),
                TieredBatchedRoundingMetricAdjuster(bounds: [1482.0, 4656.0], rates: [0.91, 1.03]),
                PercentBatchedRoundingMetricAdjuster(percent: 2.8),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 87912.8
        )
    }
}
