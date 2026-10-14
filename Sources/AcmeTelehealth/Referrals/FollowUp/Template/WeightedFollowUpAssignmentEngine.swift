import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted follow up assignment calculation.
    protocol WeightedFollowUpAssignmentFactor {
        func describe() -> String
        func adjust(_ item: WeightedFollowUpAssignment, value: Double) -> Double
    }

    final class WeightedFollowUpAssignmentCopayOffsetAdjuster: WeightedFollowUpAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: WeightedFollowUpAssignment, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class CapWeightedFollowUpAssignmentAdjuster: WeightedFollowUpAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedFollowUpAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedFollowUpAssignmentAdjuster: WeightedFollowUpAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedFollowUpAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredWeightedFollowUpAssignmentAdjuster: WeightedFollowUpAssignmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedFollowUpAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWeightedFollowUpAssignmentAdjuster: WeightedFollowUpAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedFollowUpAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedFollowUpAssignmentAdjuster: WeightedFollowUpAssignmentFactor {
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

        func adjust(_ item: WeightedFollowUpAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted follow up assignment steps in order and keeps a trace of each.
    final class WeightedFollowUpAssignmentEngine {
        var steps: [any WeightedFollowUpAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedFollowUpAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedFollowUpAssignment) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedFollowUpAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [WeightedFollowUpAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedFollowUpAssignmentEngine(_ flags: Kit.Flags.Registry) -> WeightedFollowUpAssignmentEngine {
        return WeightedFollowUpAssignmentEngine(
            steps: [
                WeightedFollowUpAssignmentCopayOffsetAdjuster(weight: 0.33),
                CapWeightedFollowUpAssignmentAdjuster(cap: 47640.0),
                RoundingWeightedFollowUpAssignmentAdjuster(step: 0.1),
                TieredWeightedFollowUpAssignmentAdjuster(
                    bounds: [1623.0, 2920.0, 5339.0, 7687.0],
                    rates: [1.12, 1.15, 1.18, 1.19]
                ),
                MinimumWeightedFollowUpAssignmentAdjuster(minimum: 22.7),
                FlaggedWeightedFollowUpAssignmentAdjuster(
                    flags: flags,
                    flag: "weighted-follow-up-assignment-primary",
                    percent: 4.2
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 56386.2
        )
    }
}
