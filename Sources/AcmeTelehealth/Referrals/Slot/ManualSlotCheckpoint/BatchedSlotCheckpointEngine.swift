import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched slot checkpoint calculation.
    protocol BatchedSlotCheckpointModifier {
        func describe() -> String
        func adjust(_ item: BatchedSlotCheckpoint, value: Double) -> Double
    }

    final class CapBatchedSlotCheckpointAdjuster: BatchedSlotCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedSlotCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumBatchedSlotCheckpointAdjuster: BatchedSlotCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedSlotCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedSlotCheckpointAdjuster: BatchedSlotCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedSlotCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedBatchedSlotCheckpointAdjuster: BatchedSlotCheckpointModifier {
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

        func adjust(_ item: BatchedSlotCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryBatchedSlotCheckpointAdjuster: BatchedSlotCheckpointModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: BatchedSlotCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched slot checkpoint steps in order and keeps a trace of each.
    final class BatchedSlotCheckpointEngine {
        var steps: [any BatchedSlotCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSlotCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedSlotCheckpoint) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [BatchedSlotCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedSlotCheckpointEngine(_ flags: Kit.Flags.Registry) -> BatchedSlotCheckpointEngine {
        return BatchedSlotCheckpointEngine(
            steps: [
                CapBatchedSlotCheckpointAdjuster(cap: 19589.0),
                MinimumBatchedSlotCheckpointAdjuster(minimum: 48.7),
                RoundingBatchedSlotCheckpointAdjuster(step: 0.5),
                FlaggedBatchedSlotCheckpointAdjuster(
                    flags: flags,
                    flag: "batched-slot-checkpoint-legacy",
                    percent: -4.9
                ),
                CategoryBatchedSlotCheckpointAdjuster(factors: ["online": 0.82, "south": 0.85, "east": 0.94]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 46842.6
        )
    }
}
