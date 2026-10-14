import AcmePlatform
import Foundation

extension Labs {
    /// One step of the batched courier batch calculation.
    protocol BatchedCourierBatchAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedCourierBatch, value: Double) -> Double
    }

    final class TieredBatchedCourierBatchAdjuster: BatchedCourierBatchAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedCourierBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BatchedCourierBatchAmountOffsetAdjuster: BatchedCourierBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: BatchedCourierBatch, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class PercentBatchedCourierBatchAdjuster: BatchedCourierBatchAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedCourierBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedBatchedCourierBatchAdjuster: BatchedCourierBatchAdjuster {
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

        func adjust(_ item: BatchedCourierBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched courier batch steps in order and keeps a trace of each.
    final class BatchedCourierBatchEngine {
        var steps: [any BatchedCourierBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCourierBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedCourierBatch) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [BatchedCourierBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedCourierBatchEngine(_ flags: Kit.Flags.Registry) -> BatchedCourierBatchEngine {
        return BatchedCourierBatchEngine(
            steps: [
                TieredBatchedCourierBatchAdjuster(
                    bounds: [1408.0, 6698.0, 6753.0, 9044.0],
                    rates: [1.12, 0.93, 0.86, 0.9]
                ),
                BatchedCourierBatchAmountOffsetAdjuster(weight: 1.2),
                PercentBatchedCourierBatchAdjuster(percent: -4.3),
                FlaggedBatchedCourierBatchAdjuster(flags: flags, flag: "batched-courier-batch-tiered", percent: -7.4),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 43328.8
        )
    }
}
