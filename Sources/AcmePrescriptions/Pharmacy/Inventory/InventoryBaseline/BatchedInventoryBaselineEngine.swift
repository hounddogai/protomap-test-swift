import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched inventory baseline calculation.
    protocol BatchedInventoryBaselineStep {
        func describe() -> String
        func adjust(_ item: BatchedInventoryBaseline, value: Double) -> Double
    }

    final class FlaggedBatchedInventoryBaselineAdjuster: BatchedInventoryBaselineStep {
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

        func adjust(_ item: BatchedInventoryBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedInventoryBaselineMinimumOffsetAdjuster: BatchedInventoryBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: BatchedInventoryBaseline, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class TieredBatchedInventoryBaselineAdjuster: BatchedInventoryBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedInventoryBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedInventoryBaselineAdjuster: BatchedInventoryBaselineStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedInventoryBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched inventory baseline steps in order and keeps a trace of each.
    final class BatchedInventoryBaselineEngine {
        var steps: [any BatchedInventoryBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedInventoryBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedInventoryBaseline) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [BatchedInventoryBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedInventoryBaselineEngine(_ flags: Kit.Flags.Registry) -> BatchedInventoryBaselineEngine {
        return BatchedInventoryBaselineEngine(
            steps: [
                FlaggedBatchedInventoryBaselineAdjuster(
                    flags: flags,
                    flag: "batched-inventory-baseline-global",
                    percent: -7.9
                ),
                BatchedInventoryBaselineMinimumOffsetAdjuster(weight: 0.84),
                TieredBatchedInventoryBaselineAdjuster(
                    bounds: [2608.0, 2677.0, 2866.0, 8034.0],
                    rates: [0.82, 0.86, 0.91, 0.9]
                ),
                PercentBatchedInventoryBaselineAdjuster(percent: 24.9),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 31660.4
        )
    }
}
