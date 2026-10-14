import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched slot snapshot calculation.
    protocol BatchedSlotSnapshotFactor {
        func describe() -> String
        func adjust(_ item: BatchedSlotSnapshot, value: Double) -> Double
    }

    final class FlaggedBatchedSlotSnapshotAdjuster: BatchedSlotSnapshotFactor {
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

        func adjust(_ item: BatchedSlotSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedSlotSnapshotAdjuster: BatchedSlotSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedSlotSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredBatchedSlotSnapshotAdjuster: BatchedSlotSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedSlotSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBatchedSlotSnapshotAdjuster: BatchedSlotSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedSlotSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ChannelBatchedSlotSnapshotAdjuster: BatchedSlotSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: BatchedSlotSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched slot snapshot steps in order and keeps a trace of each.
    final class BatchedSlotSnapshotEngine {
        var steps: [any BatchedSlotSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSlotSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedSlotSnapshot) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [BatchedSlotSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedSlotSnapshotEngine(_ flags: Kit.Flags.Registry) -> BatchedSlotSnapshotEngine {
        return BatchedSlotSnapshotEngine(
            steps: [
                FlaggedBatchedSlotSnapshotAdjuster(flags: flags, flag: "batched-slot-snapshot-capped", percent: -5.5),
                RoundingBatchedSlotSnapshotAdjuster(step: 0.05),
                TieredBatchedSlotSnapshotAdjuster(bounds: [1829.0, 4847.0, 5069.0], rates: [0.87, 0.86, 0.82]),
                MinimumBatchedSlotSnapshotAdjuster(minimum: 7.1),
                ChannelBatchedSlotSnapshotAdjuster(factors: ["east": 1.09, "north": 1.04, "west": 0.73]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 16828.4
        )
    }
}
