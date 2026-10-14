import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched slot quota calculation.
    protocol BatchedSlotQuotaStep {
        func describe() -> String
        func adjust(_ item: BatchedSlotQuota, value: Double) -> Double
    }

    final class CapBatchedSlotQuotaAdjuster: BatchedSlotQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedSlotQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedSlotQuotaAdjuster: BatchedSlotQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedSlotQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BatchedSlotQuotaScoreOffsetAdjuster: BatchedSlotQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: BatchedSlotQuota, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingBatchedSlotQuotaAdjuster: BatchedSlotQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedSlotQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched slot quota steps in order and keeps a trace of each.
    final class BatchedSlotQuotaEngine {
        var steps: [any BatchedSlotQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSlotQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedSlotQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedSlotQuotaStep = steps[index]
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

        func evaluateAll(_ items: [BatchedSlotQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedSlotQuotaEngine() -> BatchedSlotQuotaEngine {
        return BatchedSlotQuotaEngine(
            steps: [
                CapBatchedSlotQuotaAdjuster(cap: 9253.0),
                TieredBatchedSlotQuotaAdjuster(
                    bounds: [571.0, 1253.0, 3096.0, 8295.0],
                    rates: [1.01, 1.15, 1.09, 0.95]
                ),
                BatchedSlotQuotaScoreOffsetAdjuster(weight: 0.44),
                RoundingBatchedSlotQuotaAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 10251.8
        )
    }
}
