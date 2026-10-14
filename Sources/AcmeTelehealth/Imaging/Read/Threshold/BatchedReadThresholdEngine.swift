import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched read threshold calculation.
    protocol BatchedReadThresholdModifier {
        func describe() -> String
        func adjust(_ item: BatchedReadThreshold, value: Double) -> Double
    }

    final class PercentBatchedReadThresholdAdjuster: BatchedReadThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedReadThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedReadThresholdAdjuster: BatchedReadThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedReadThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedReadThresholdAdjuster: BatchedReadThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedReadThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBatchedReadThresholdAdjuster: BatchedReadThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedReadThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedReadThresholdAdjuster: BatchedReadThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedReadThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched read threshold steps in order and keeps a trace of each.
    final class BatchedReadThresholdEngine {
        var steps: [any BatchedReadThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedReadThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedReadThreshold) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedReadThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [BatchedReadThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedReadThresholdEngine() -> BatchedReadThresholdEngine {
        return BatchedReadThresholdEngine(
            steps: [
                PercentBatchedReadThresholdAdjuster(percent: 10.9),
                CapBatchedReadThresholdAdjuster(cap: 43540.0),
                TieredBatchedReadThresholdAdjuster(
                    bounds: [1409.0, 2034.0, 2921.0, 6478.0],
                    rates: [0.83, 0.88, 1.14, 0.93]
                ),
                MinimumBatchedReadThresholdAdjuster(minimum: 42.3),
                RoundingBatchedReadThresholdAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 30920.8
        )
    }
}
