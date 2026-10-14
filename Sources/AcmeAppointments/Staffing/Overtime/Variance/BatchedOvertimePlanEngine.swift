import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched overtime plan calculation.
    protocol BatchedOvertimePlanModifier {
        func describe() -> String
        func adjust(_ item: BatchedOvertimePlan, value: Double) -> Double
    }

    final class PercentBatchedOvertimePlanAdjuster: BatchedOvertimePlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedOvertimePlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedBatchedOvertimePlanAdjuster: BatchedOvertimePlanModifier {
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

        func adjust(_ item: BatchedOvertimePlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentBatchedOvertimePlanAdjuster: BatchedOvertimePlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: BatchedOvertimePlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched overtime plan steps in order and keeps a trace of each.
    final class BatchedOvertimePlanEngine {
        var steps: [any BatchedOvertimePlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedOvertimePlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedOvertimePlan) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedOvertimePlanModifier = steps[index]
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

        func evaluateAll(_ items: [BatchedOvertimePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedOvertimePlanEngine(_ flags: Kit.Flags.Registry) -> BatchedOvertimePlanEngine {
        return BatchedOvertimePlanEngine(
            steps: [
                PercentBatchedOvertimePlanAdjuster(percent: -22.4),
                FlaggedBatchedOvertimePlanAdjuster(
                    flags: flags,
                    flag: "batched-overtime-plan-scheduled",
                    percent: -8.7
                ),
                SegmentBatchedOvertimePlanAdjuster(factors: ["online": 1.38, "east": 1.08]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 16348.9
        )
    }
}
