import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling priority assignment calculation.
    protocol RollingPriorityAssignmentModifier {
        func describe() -> String
        func adjust(_ item: RollingPriorityAssignment, value: Double) -> Double
    }

    final class RollingPriorityAssignmentDosageMgOffsetAdjuster: RollingPriorityAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: RollingPriorityAssignment, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingRollingPriorityAssignmentAdjuster: RollingPriorityAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingPriorityAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRollingPriorityAssignmentAdjuster: RollingPriorityAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingPriorityAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingPriorityAssignmentAdjuster: RollingPriorityAssignmentModifier {
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

        func adjust(_ item: RollingPriorityAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRollingPriorityAssignmentAdjuster: RollingPriorityAssignmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingPriorityAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentRollingPriorityAssignmentAdjuster: RollingPriorityAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: RollingPriorityAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling priority assignment steps in order and keeps a trace of each.
    final class RollingPriorityAssignmentEngine {
        var steps: [any RollingPriorityAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingPriorityAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingPriorityAssignment) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingPriorityAssignmentModifier = steps[index]
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

        func evaluateAll(_ items: [RollingPriorityAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingPriorityAssignmentEngine(_ flags: Kit.Flags.Registry) -> RollingPriorityAssignmentEngine {
        return RollingPriorityAssignmentEngine(
            steps: [
                RollingPriorityAssignmentDosageMgOffsetAdjuster(weight: 1.43),
                RoundingRollingPriorityAssignmentAdjuster(step: 1.0),
                TieredRollingPriorityAssignmentAdjuster(bounds: [2329.0, 2424.0], rates: [1.17, 1.13]),
                FlaggedRollingPriorityAssignmentAdjuster(
                    flags: flags,
                    flag: "rolling-priority-assignment-primary",
                    percent: -9.2
                ),
                PercentRollingPriorityAssignmentAdjuster(percent: 22.4),
                SegmentRollingPriorityAssignmentAdjuster(factors: ["retail": 0.94, "north": 0.9]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 57700.4
        )
    }
}
