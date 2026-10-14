import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched recall profile calculation.
    protocol BatchedRecallProfileFactor {
        func describe() -> String
        func adjust(_ item: BatchedRecallProfile, value: Double) -> Double
    }

    final class BatchedRecallProfileFloorValueOffsetAdjuster: BatchedRecallProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: BatchedRecallProfile, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class RoundingBatchedRecallProfileAdjuster: BatchedRecallProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedRecallProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapBatchedRecallProfileAdjuster: BatchedRecallProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedRecallProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedRecallProfileAdjuster: BatchedRecallProfileFactor {
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

        func adjust(_ item: BatchedRecallProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedRecallProfileAdjuster: BatchedRecallProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedRecallProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentBatchedRecallProfileAdjuster: BatchedRecallProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedRecallProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched recall profile steps in order and keeps a trace of each.
    final class BatchedRecallProfileEngine {
        var steps: [any BatchedRecallProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRecallProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedRecallProfile) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedRecallProfileFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedRecallProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedRecallProfileEngine(_ flags: Kit.Flags.Registry) -> BatchedRecallProfileEngine {
        return BatchedRecallProfileEngine(
            steps: [
                BatchedRecallProfileFloorValueOffsetAdjuster(weight: 1.03),
                RoundingBatchedRecallProfileAdjuster(step: 1.0),
                CapBatchedRecallProfileAdjuster(cap: 7892.0),
                FlaggedBatchedRecallProfileAdjuster(
                    flags: flags,
                    flag: "batched-recall-profile-seasonal",
                    percent: -6.6
                ),
                MinimumBatchedRecallProfileAdjuster(minimum: 32.0),
                PercentBatchedRecallProfileAdjuster(percent: -8.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 7533.6
        )
    }
}
