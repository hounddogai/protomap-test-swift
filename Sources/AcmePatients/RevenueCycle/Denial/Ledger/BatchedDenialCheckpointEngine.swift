import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched denial checkpoint calculation.
    protocol BatchedDenialCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedDenialCheckpoint, value: Double) -> Double
    }

    final class PercentBatchedDenialCheckpointAdjuster: BatchedDenialCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedDenialCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedBatchedDenialCheckpointAdjuster: BatchedDenialCheckpointAdjuster {
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

        func adjust(_ item: BatchedDenialCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedDenialCheckpointWindowDaysOffsetAdjuster: BatchedDenialCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: BatchedDenialCheckpoint, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the batched denial checkpoint steps in order and keeps a trace of each.
    final class BatchedDenialCheckpointEngine {
        var steps: [any BatchedDenialCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDenialCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedDenialCheckpoint) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedDenialCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedDenialCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedDenialCheckpointEngine(_ flags: Kit.Flags.Registry) -> BatchedDenialCheckpointEngine {
        return BatchedDenialCheckpointEngine(
            steps: [
                PercentBatchedDenialCheckpointAdjuster(percent: 8.9),
                FlaggedBatchedDenialCheckpointAdjuster(
                    flags: flags,
                    flag: "batched-denial-checkpoint-regional",
                    percent: 0.8
                ),
                BatchedDenialCheckpointWindowDaysOffsetAdjuster(weight: 0.04),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 15273.2
        )
    }
}
