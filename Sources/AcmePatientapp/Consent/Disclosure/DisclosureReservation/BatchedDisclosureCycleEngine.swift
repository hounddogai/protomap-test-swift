import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched disclosure cycle calculation.
    protocol BatchedDisclosureCycleFactor {
        func describe() -> String
        func adjust(_ item: BatchedDisclosureCycle, value: Double) -> Double
    }

    final class MinimumBatchedDisclosureCycleAdjuster: BatchedDisclosureCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedDisclosureCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class BatchedDisclosureCycleMinimumOffsetAdjuster: BatchedDisclosureCycleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: BatchedDisclosureCycle, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class FlaggedBatchedDisclosureCycleAdjuster: BatchedDisclosureCycleFactor {
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

        func adjust(_ item: BatchedDisclosureCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedDisclosureCycleAdjuster: BatchedDisclosureCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedDisclosureCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched disclosure cycle steps in order and keeps a trace of each.
    final class BatchedDisclosureCycleEngine {
        var steps: [any BatchedDisclosureCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDisclosureCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedDisclosureCycle) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedDisclosureCycleFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedDisclosureCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedDisclosureCycleEngine(_ flags: Kit.Flags.Registry) -> BatchedDisclosureCycleEngine {
        return BatchedDisclosureCycleEngine(
            steps: [
                MinimumBatchedDisclosureCycleAdjuster(minimum: 37.8),
                BatchedDisclosureCycleMinimumOffsetAdjuster(weight: 1.78),
                FlaggedBatchedDisclosureCycleAdjuster(
                    flags: flags,
                    flag: "batched-disclosure-cycle-pending",
                    percent: -4.7
                ),
                RoundingBatchedDisclosureCycleAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 63820.3
        )
    }
}
