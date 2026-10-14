import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched discharge plan draft calculation.
    protocol BatchedDischargePlanDraftStep {
        func describe() -> String
        func adjust(_ item: BatchedDischargePlanDraft, value: Double) -> Double
    }

    final class RoundingBatchedDischargePlanDraftAdjuster: BatchedDischargePlanDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedDischargePlanDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BatchedDischargePlanDraftUpdatedAtOffsetAdjuster: BatchedDischargePlanDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: BatchedDischargePlanDraft, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class MinimumBatchedDischargePlanDraftAdjuster: BatchedDischargePlanDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedDischargePlanDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBatchedDischargePlanDraftAdjuster: BatchedDischargePlanDraftStep {
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

        func adjust(_ item: BatchedDischargePlanDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched discharge plan draft steps in order and keeps a trace of each.
    final class BatchedDischargePlanDraftEngine {
        var steps: [any BatchedDischargePlanDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDischargePlanDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedDischargePlanDraft) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedDischargePlanDraftStep = steps[index]
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

        func evaluateAll(_ items: [BatchedDischargePlanDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedDischargePlanDraftEngine(_ flags: Kit.Flags.Registry) -> BatchedDischargePlanDraftEngine {
        return BatchedDischargePlanDraftEngine(
            steps: [
                RoundingBatchedDischargePlanDraftAdjuster(step: 1.0),
                BatchedDischargePlanDraftUpdatedAtOffsetAdjuster(weight: 0.6),
                MinimumBatchedDischargePlanDraftAdjuster(minimum: 4.4),
                FlaggedBatchedDischargePlanDraftAdjuster(
                    flags: flags,
                    flag: "batched-discharge-plan-draft-lenient",
                    percent: 8.6
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 7837.9
        )
    }
}
