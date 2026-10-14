import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched charge entry calculation.
    protocol BatchedChargeEntryStep {
        func describe() -> String
        func adjust(_ item: BatchedChargeEntry, value: Double) -> Double
    }

    final class PercentBatchedChargeEntryAdjuster: BatchedChargeEntryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedChargeEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedChargeEntryAdjuster: BatchedChargeEntryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedChargeEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class BatchedChargeEntryQuantityOffsetAdjuster: BatchedChargeEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: BatchedChargeEntry, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredBatchedChargeEntryAdjuster: BatchedChargeEntryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedChargeEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched charge entry steps in order and keeps a trace of each.
    final class BatchedChargeEntryEngine {
        var steps: [any BatchedChargeEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedChargeEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedChargeEntry) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedChargeEntryStep = steps[index]
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

        func evaluateAll(_ items: [BatchedChargeEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedChargeEntryEngine() -> BatchedChargeEntryEngine {
        return BatchedChargeEntryEngine(
            steps: [
                PercentBatchedChargeEntryAdjuster(percent: -8.6),
                MinimumBatchedChargeEntryAdjuster(minimum: 4.6),
                BatchedChargeEntryQuantityOffsetAdjuster(weight: 0.78),
                TieredBatchedChargeEntryAdjuster(bounds: [3076.0, 6629.0], rates: [0.95, 0.91]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 36801.3
        )
    }
}
