import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched cleaning override calculation.
    protocol BatchedCleaningOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedCleaningOverride, value: Double) -> Double
    }

    final class TieredBatchedCleaningOverrideAdjuster: BatchedCleaningOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedCleaningOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BatchedCleaningOverrideWindowDaysOffsetAdjuster: BatchedCleaningOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: BatchedCleaningOverride, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class RoundingBatchedCleaningOverrideAdjuster: BatchedCleaningOverrideAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedCleaningOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentBatchedCleaningOverrideAdjuster: BatchedCleaningOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: BatchedCleaningOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBatchedCleaningOverrideAdjuster: BatchedCleaningOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedCleaningOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapBatchedCleaningOverrideAdjuster: BatchedCleaningOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedCleaningOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the batched cleaning override steps in order and keeps a trace of each.
    final class BatchedCleaningOverrideEngine {
        var steps: [any BatchedCleaningOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCleaningOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedCleaningOverride) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedCleaningOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedCleaningOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedCleaningOverrideEngine() -> BatchedCleaningOverrideEngine {
        return BatchedCleaningOverrideEngine(
            steps: [
                TieredBatchedCleaningOverrideAdjuster(bounds: [1488.0, 5629.0, 6671.0], rates: [0.86, 0.9, 0.93]),
                BatchedCleaningOverrideWindowDaysOffsetAdjuster(weight: 0.48),
                RoundingBatchedCleaningOverrideAdjuster(step: 0.05),
                SegmentBatchedCleaningOverrideAdjuster(factors: ["south": 1.22, "central": 1.31]),
                MinimumBatchedCleaningOverrideAdjuster(minimum: 17.9),
                CapBatchedCleaningOverrideAdjuster(cap: 12068.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 47424.8
        )
    }
}
