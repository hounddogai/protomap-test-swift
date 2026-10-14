import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched task plan calculation.
    protocol BatchedTaskPlanStep {
        func describe() -> String
        func adjust(_ item: BatchedTaskPlan, value: Double) -> Double
    }

    final class BatchedTaskPlanRatioOffsetAdjuster: BatchedTaskPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: BatchedTaskPlan, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class FlaggedBatchedTaskPlanAdjuster: BatchedTaskPlanStep {
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

        func adjust(_ item: BatchedTaskPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBatchedTaskPlanAdjuster: BatchedTaskPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedTaskPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBatchedTaskPlanAdjuster: BatchedTaskPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedTaskPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentBatchedTaskPlanAdjuster: BatchedTaskPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedTaskPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedTaskPlanAdjuster: BatchedTaskPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedTaskPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched task plan steps in order and keeps a trace of each.
    final class BatchedTaskPlanEngine {
        var steps: [any BatchedTaskPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedTaskPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedTaskPlan) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedTaskPlanStep = steps[index]
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

        func evaluateAll(_ items: [BatchedTaskPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedTaskPlanEngine(_ flags: Kit.Flags.Registry) -> BatchedTaskPlanEngine {
        return BatchedTaskPlanEngine(
            steps: [
                BatchedTaskPlanRatioOffsetAdjuster(weight: 0.21),
                FlaggedBatchedTaskPlanAdjuster(flags: flags, flag: "batched-task-plan-fallback", percent: 6.8),
                TieredBatchedTaskPlanAdjuster(bounds: [779.0, 7242.0], rates: [1.1, 1.06]),
                MinimumBatchedTaskPlanAdjuster(minimum: 38.8),
                PercentBatchedTaskPlanAdjuster(percent: -9.5),
                RoundingBatchedTaskPlanAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 18283.2
        )
    }
}
