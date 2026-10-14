import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched slot tier calculation.
    protocol BatchedSlotTierStep {
        func describe() -> String
        func adjust(_ item: BatchedSlotTier, value: Double) -> Double
    }

    final class TieredBatchedSlotTierAdjuster: BatchedSlotTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedSlotTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BatchedSlotTierExpiresAtOffsetAdjuster: BatchedSlotTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: BatchedSlotTier, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class CapBatchedSlotTierAdjuster: BatchedSlotTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedSlotTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleBatchedSlotTierAdjuster: BatchedSlotTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: BatchedSlotTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedSlotTierAdjuster: BatchedSlotTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedSlotTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched slot tier steps in order and keeps a trace of each.
    final class BatchedSlotTierEngine {
        var steps: [any BatchedSlotTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSlotTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedSlotTier) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedSlotTierStep = steps[index]
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

        func evaluateAll(_ items: [BatchedSlotTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedSlotTierEngine() -> BatchedSlotTierEngine {
        return BatchedSlotTierEngine(
            steps: [
                TieredBatchedSlotTierAdjuster(bounds: [4611.0, 5808.0], rates: [1.0, 0.99]),
                BatchedSlotTierExpiresAtOffsetAdjuster(weight: 1.9),
                CapBatchedSlotTierAdjuster(cap: 25364.0),
                LocaleBatchedSlotTierAdjuster(factors: ["retail": 1.2]),
                RoundingBatchedSlotTierAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 86883.4
        )
    }
}
