import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched isolation rollup calculation.
    protocol BatchedIsolationRollupStep {
        func describe() -> String
        func adjust(_ item: BatchedIsolationRollup, value: Double) -> Double
    }

    final class TieredBatchedIsolationRollupAdjuster: BatchedIsolationRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedIsolationRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBatchedIsolationRollupAdjuster: BatchedIsolationRollupStep {
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

        func adjust(_ item: BatchedIsolationRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedIsolationRollupAdjuster: BatchedIsolationRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedIsolationRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched isolation rollup steps in order and keeps a trace of each.
    final class BatchedIsolationRollupEngine {
        var steps: [any BatchedIsolationRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedIsolationRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedIsolationRollup) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedIsolationRollupStep = steps[index]
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

        func evaluateAll(_ items: [BatchedIsolationRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedIsolationRollupEngine(_ flags: Kit.Flags.Registry) -> BatchedIsolationRollupEngine {
        return BatchedIsolationRollupEngine(
            steps: [
                TieredBatchedIsolationRollupAdjuster(bounds: [3722.0, 3924.0], rates: [1.19, 1.07]),
                FlaggedBatchedIsolationRollupAdjuster(
                    flags: flags,
                    flag: "batched-isolation-rollup-regional",
                    percent: -1.1
                ),
                RoundingBatchedIsolationRollupAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 81293.2
        )
    }
}
