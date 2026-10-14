import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched charge quota calculation.
    protocol BatchedChargeQuotaStep {
        func describe() -> String
        func adjust(_ item: BatchedChargeQuota, value: Double) -> Double
    }

    final class TieredBatchedChargeQuotaAdjuster: BatchedChargeQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedChargeQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedChargeQuotaAdjuster: BatchedChargeQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedChargeQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceBatchedChargeQuotaAdjuster: BatchedChargeQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: BatchedChargeQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapBatchedChargeQuotaAdjuster: BatchedChargeQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedChargeQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingBatchedChargeQuotaAdjuster: BatchedChargeQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedChargeQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBatchedChargeQuotaAdjuster: BatchedChargeQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedChargeQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched charge quota steps in order and keeps a trace of each.
    final class BatchedChargeQuotaEngine {
        var steps: [any BatchedChargeQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedChargeQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedChargeQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedChargeQuotaStep = steps[index]
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

        func evaluateAll(_ items: [BatchedChargeQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedChargeQuotaEngine() -> BatchedChargeQuotaEngine {
        return BatchedChargeQuotaEngine(
            steps: [
                TieredBatchedChargeQuotaAdjuster(bounds: [3034.0, 4426.0], rates: [1.07, 0.95]),
                PercentBatchedChargeQuotaAdjuster(percent: -7.0),
                SourceBatchedChargeQuotaAdjuster(factors: ["retail": 0.88, "north": 1.36]),
                CapBatchedChargeQuotaAdjuster(cap: 25742.0),
                RoundingBatchedChargeQuotaAdjuster(step: 0.25),
                MinimumBatchedChargeQuotaAdjuster(minimum: 33.6),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 11795.6
        )
    }
}
