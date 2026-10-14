import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched follow up plan calculation.
    protocol BatchedFollowUpPlanFactor {
        func describe() -> String
        func adjust(_ item: BatchedFollowUpPlan, value: Double) -> Double
    }

    final class CapBatchedFollowUpPlanAdjuster: BatchedFollowUpPlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedFollowUpPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedFollowUpPlanAdjuster: BatchedFollowUpPlanFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedFollowUpPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedFollowUpPlanExpiresAtOffsetAdjuster: BatchedFollowUpPlanFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: BatchedFollowUpPlan, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumBatchedFollowUpPlanAdjuster: BatchedFollowUpPlanFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedFollowUpPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleBatchedFollowUpPlanAdjuster: BatchedFollowUpPlanFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedFollowUpPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched follow up plan steps in order and keeps a trace of each.
    final class BatchedFollowUpPlanEngine {
        var steps: [any BatchedFollowUpPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedFollowUpPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedFollowUpPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedFollowUpPlanFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedFollowUpPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedFollowUpPlanEngine() -> BatchedFollowUpPlanEngine {
        return BatchedFollowUpPlanEngine(
            steps: [
                CapBatchedFollowUpPlanAdjuster(cap: 46378.0),
                PercentBatchedFollowUpPlanAdjuster(percent: -11.5),
                BatchedFollowUpPlanExpiresAtOffsetAdjuster(weight: 0.28),
                MinimumBatchedFollowUpPlanAdjuster(minimum: 32.0),
                TitleBatchedFollowUpPlanAdjuster(factors: ["retail": 0.94, "west": 1.16]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 71376.3
        )
    }
}
