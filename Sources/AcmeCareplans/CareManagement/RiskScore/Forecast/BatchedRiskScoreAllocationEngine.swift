import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched risk score allocation calculation.
    protocol BatchedRiskScoreAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedRiskScoreAllocation, value: Double) -> Double
    }

    final class CapBatchedRiskScoreAllocationAdjuster: BatchedRiskScoreAllocationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedRiskScoreAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumBatchedRiskScoreAllocationAdjuster: BatchedRiskScoreAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedRiskScoreAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedRiskScoreAllocationAdjuster: BatchedRiskScoreAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRiskScoreAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedRiskScoreAllocationAdjuster: BatchedRiskScoreAllocationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedRiskScoreAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedRiskScoreAllocationAdjuster: BatchedRiskScoreAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedRiskScoreAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BatchedRiskScoreAllocationUpdatedAtOffsetAdjuster: BatchedRiskScoreAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: BatchedRiskScoreAllocation, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the batched risk score allocation steps in order and keeps a trace of each.
    final class BatchedRiskScoreAllocationEngine {
        var steps: [any BatchedRiskScoreAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRiskScoreAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedRiskScoreAllocation) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [BatchedRiskScoreAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedRiskScoreAllocationEngine() -> BatchedRiskScoreAllocationEngine {
        return BatchedRiskScoreAllocationEngine(
            steps: [
                CapBatchedRiskScoreAllocationAdjuster(cap: 7371.0),
                MinimumBatchedRiskScoreAllocationAdjuster(minimum: 35.3),
                TieredBatchedRiskScoreAllocationAdjuster(bounds: [295.0, 973.0, 9114.0], rates: [1.14, 1.12, 0.89]),
                PercentBatchedRiskScoreAllocationAdjuster(percent: 21.5),
                RoundingBatchedRiskScoreAllocationAdjuster(step: 0.05),
                BatchedRiskScoreAllocationUpdatedAtOffsetAdjuster(weight: 0.1),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 30061.8
        )
    }
}
