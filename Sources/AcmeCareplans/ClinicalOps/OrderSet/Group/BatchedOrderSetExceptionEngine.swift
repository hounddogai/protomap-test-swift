import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched order set exception calculation.
    protocol BatchedOrderSetExceptionFactor {
        func describe() -> String
        func adjust(_ item: BatchedOrderSetException, value: Double) -> Double
    }

    final class CapBatchedOrderSetExceptionAdjuster: BatchedOrderSetExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedOrderSetException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedOrderSetExceptionAdjuster: BatchedOrderSetExceptionFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: BatchedOrderSetException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedOrderSetExceptionAdjuster: BatchedOrderSetExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedOrderSetException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BatchedOrderSetExceptionDiscountOffsetAdjuster: BatchedOrderSetExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: BatchedOrderSetException, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class PercentBatchedOrderSetExceptionAdjuster: BatchedOrderSetExceptionFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedOrderSetException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBatchedOrderSetExceptionAdjuster: BatchedOrderSetExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedOrderSetException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched order set exception steps in order and keeps a trace of each.
    final class BatchedOrderSetExceptionEngine {
        var steps: [any BatchedOrderSetExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedOrderSetExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedOrderSetException) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [BatchedOrderSetException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedOrderSetExceptionEngine(_ flags: Kit.Flags.Registry) -> BatchedOrderSetExceptionEngine {
        return BatchedOrderSetExceptionEngine(
            steps: [
                CapBatchedOrderSetExceptionAdjuster(cap: 45699.0),
                FlaggedBatchedOrderSetExceptionAdjuster(
                    flags: flags,
                    flag: "batched-order-set-exception-lenient",
                    percent: 9.2
                ),
                RoundingBatchedOrderSetExceptionAdjuster(step: 0.05),
                BatchedOrderSetExceptionDiscountOffsetAdjuster(weight: 1.8),
                PercentBatchedOrderSetExceptionAdjuster(percent: 8.5),
                TieredBatchedOrderSetExceptionAdjuster(bounds: [2135.0, 3937.0], rates: [1.08, 0.84]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 20499.8
        )
    }
}
