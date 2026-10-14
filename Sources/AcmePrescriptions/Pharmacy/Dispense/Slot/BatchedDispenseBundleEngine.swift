import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched dispense bundle calculation.
    protocol BatchedDispenseBundleAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedDispenseBundle, value: Double) -> Double
    }

    final class MinimumBatchedDispenseBundleAdjuster: BatchedDispenseBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedDispenseBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedDispenseBundleAdjuster: BatchedDispenseBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedDispenseBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BatchedDispenseBundleCreatedAtOffsetAdjuster: BatchedDispenseBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: BatchedDispenseBundle, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentBatchedDispenseBundleAdjuster: BatchedDispenseBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedDispenseBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched dispense bundle steps in order and keeps a trace of each.
    final class BatchedDispenseBundleEngine {
        var steps: [any BatchedDispenseBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDispenseBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedDispenseBundle) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [BatchedDispenseBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedDispenseBundleEngine() -> BatchedDispenseBundleEngine {
        return BatchedDispenseBundleEngine(
            steps: [
                MinimumBatchedDispenseBundleAdjuster(minimum: 2.1),
                TieredBatchedDispenseBundleAdjuster(bounds: [4877.0, 6815.0, 8540.0], rates: [0.84, 1.07, 1.06]),
                BatchedDispenseBundleCreatedAtOffsetAdjuster(weight: 1.06),
                PercentBatchedDispenseBundleAdjuster(percent: -6.6),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 99335.8
        )
    }
}
