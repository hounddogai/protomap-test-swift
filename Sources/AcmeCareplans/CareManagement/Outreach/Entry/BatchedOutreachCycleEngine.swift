import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched outreach cycle calculation.
    protocol BatchedOutreachCycleStep {
        func describe() -> String
        func adjust(_ item: BatchedOutreachCycle, value: Double) -> Double
    }

    final class PercentBatchedOutreachCycleAdjuster: BatchedOutreachCycleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedOutreachCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedOutreachCycleAdjuster: BatchedOutreachCycleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedOutreachCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedOutreachCycleAdjuster: BatchedOutreachCycleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedOutreachCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapBatchedOutreachCycleAdjuster: BatchedOutreachCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedOutreachCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedOutreachCycleAdjuster: BatchedOutreachCycleStep {
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

        func adjust(_ item: BatchedOutreachCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedOutreachCycleDiscountOffsetAdjuster: BatchedOutreachCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: BatchedOutreachCycle, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the batched outreach cycle steps in order and keeps a trace of each.
    final class BatchedOutreachCycleEngine {
        var steps: [any BatchedOutreachCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedOutreachCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedOutreachCycle) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedOutreachCycleStep = steps[index]
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

        func evaluateAll(_ items: [BatchedOutreachCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedOutreachCycleEngine(_ flags: Kit.Flags.Registry) -> BatchedOutreachCycleEngine {
        return BatchedOutreachCycleEngine(
            steps: [
                PercentBatchedOutreachCycleAdjuster(percent: 9.3),
                MinimumBatchedOutreachCycleAdjuster(minimum: 23.1),
                RoundingBatchedOutreachCycleAdjuster(step: 0.1),
                CapBatchedOutreachCycleAdjuster(cap: 18255.0),
                FlaggedBatchedOutreachCycleAdjuster(
                    flags: flags,
                    flag: "batched-outreach-cycle-seasonal",
                    percent: -0.4
                ),
                BatchedOutreachCycleDiscountOffsetAdjuster(weight: 1.68),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 92640.0
        )
    }
}
