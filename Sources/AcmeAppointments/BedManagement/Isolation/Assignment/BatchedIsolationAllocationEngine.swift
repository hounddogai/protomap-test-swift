import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched isolation allocation calculation.
    protocol BatchedIsolationAllocationFactor {
        func describe() -> String
        func adjust(_ item: BatchedIsolationAllocation, value: Double) -> Double
    }

    final class TieredBatchedIsolationAllocationAdjuster: BatchedIsolationAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedIsolationAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentBatchedIsolationAllocationAdjuster: BatchedIsolationAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: BatchedIsolationAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedBatchedIsolationAllocationAdjuster: BatchedIsolationAllocationFactor {
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

        func adjust(_ item: BatchedIsolationAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedIsolationAllocationExpiresAtOffsetAdjuster: BatchedIsolationAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: BatchedIsolationAllocation, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class PercentBatchedIsolationAllocationAdjuster: BatchedIsolationAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedIsolationAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedIsolationAllocationAdjuster: BatchedIsolationAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedIsolationAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched isolation allocation steps in order and keeps a trace of each.
    final class BatchedIsolationAllocationEngine {
        var steps: [any BatchedIsolationAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedIsolationAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedIsolationAllocation) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedIsolationAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedIsolationAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedIsolationAllocationEngine(_ flags: Kit.Flags.Registry) -> BatchedIsolationAllocationEngine {
        return BatchedIsolationAllocationEngine(
            steps: [
                TieredBatchedIsolationAllocationAdjuster(bounds: [6015.0, 7982.0], rates: [0.86, 1.06]),
                SegmentBatchedIsolationAllocationAdjuster(factors: ["south": 0.84, "north": 1.38, "central": 1.18]),
                FlaggedBatchedIsolationAllocationAdjuster(
                    flags: flags,
                    flag: "batched-isolation-allocation-capped",
                    percent: -2.0
                ),
                BatchedIsolationAllocationExpiresAtOffsetAdjuster(weight: 0.77),
                PercentBatchedIsolationAllocationAdjuster(percent: -23.5),
                RoundingBatchedIsolationAllocationAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 12000.2
        )
    }
}
