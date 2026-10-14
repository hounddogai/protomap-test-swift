import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched network cycle calculation.
    protocol BatchedNetworkCycleFactor {
        func describe() -> String
        func adjust(_ item: BatchedNetworkCycle, value: Double) -> Double
    }

    final class TieredBatchedNetworkCycleAdjuster: BatchedNetworkCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedNetworkCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceBatchedNetworkCycleAdjuster: BatchedNetworkCycleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: BatchedNetworkCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedNetworkCycleAdjuster: BatchedNetworkCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedNetworkCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapBatchedNetworkCycleAdjuster: BatchedNetworkCycleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedNetworkCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedNetworkCycleAdjuster: BatchedNetworkCycleFactor {
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

        func adjust(_ item: BatchedNetworkCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedNetworkCycleAdjuster: BatchedNetworkCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedNetworkCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched network cycle steps in order and keeps a trace of each.
    final class BatchedNetworkCycleEngine {
        var steps: [any BatchedNetworkCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedNetworkCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedNetworkCycle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedNetworkCycleFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedNetworkCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedNetworkCycleEngine(_ flags: Kit.Flags.Registry) -> BatchedNetworkCycleEngine {
        return BatchedNetworkCycleEngine(
            steps: [
                TieredBatchedNetworkCycleAdjuster(bounds: [1727.0, 4031.0, 5561.0], rates: [0.85, 0.95, 0.86]),
                SourceBatchedNetworkCycleAdjuster(factors: ["east": 0.89]),
                RoundingBatchedNetworkCycleAdjuster(step: 5.0),
                CapBatchedNetworkCycleAdjuster(cap: 4802.0),
                FlaggedBatchedNetworkCycleAdjuster(flags: flags, flag: "batched-network-cycle-rolling", percent: -8.9),
                MinimumBatchedNetworkCycleAdjuster(minimum: 31.9),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 55609.3
        )
    }
}
