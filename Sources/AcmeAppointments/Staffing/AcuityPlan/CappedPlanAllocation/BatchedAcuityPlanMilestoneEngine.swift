import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched acuity plan milestone calculation.
    protocol BatchedAcuityPlanMilestoneFactor {
        func describe() -> String
        func adjust(_ item: BatchedAcuityPlanMilestone, value: Double) -> Double
    }

    final class FlaggedBatchedAcuityPlanMilestoneAdjuster: BatchedAcuityPlanMilestoneFactor {
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

        func adjust(_ item: BatchedAcuityPlanMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedAcuityPlanMilestoneCopayOffsetAdjuster: BatchedAcuityPlanMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: BatchedAcuityPlanMilestone, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class TieredBatchedAcuityPlanMilestoneAdjuster: BatchedAcuityPlanMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedAcuityPlanMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBatchedAcuityPlanMilestoneAdjuster: BatchedAcuityPlanMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedAcuityPlanMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched acuity plan milestone steps in order and keeps a trace of each.
    final class BatchedAcuityPlanMilestoneEngine {
        var steps: [any BatchedAcuityPlanMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedAcuityPlanMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedAcuityPlanMilestone) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedAcuityPlanMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedAcuityPlanMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedAcuityPlanMilestoneEngine(_ flags: Kit.Flags.Registry) -> BatchedAcuityPlanMilestoneEngine {
        return BatchedAcuityPlanMilestoneEngine(
            steps: [
                FlaggedBatchedAcuityPlanMilestoneAdjuster(
                    flags: flags,
                    flag: "batched-acuity-plan-milestone-global",
                    percent: 9.6
                ),
                BatchedAcuityPlanMilestoneCopayOffsetAdjuster(weight: 1.74),
                TieredBatchedAcuityPlanMilestoneAdjuster(
                    bounds: [5147.0, 8497.0, 9584.0, 9955.0],
                    rates: [0.95, 1.06, 0.8, 1.0]
                ),
                MinimumBatchedAcuityPlanMilestoneAdjuster(minimum: 30.4),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 33221.1
        )
    }
}
