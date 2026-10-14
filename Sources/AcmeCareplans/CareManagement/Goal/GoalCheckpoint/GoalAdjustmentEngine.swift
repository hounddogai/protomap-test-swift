import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal adjustment calculation.
    protocol GoalAdjustmentStep {
        func describe() -> String
        func adjust(_ item: GoalAdjustment, value: Double) -> Double
    }

    final class GoalAdjustmentQuantityOffsetAdjuster: GoalAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: GoalAdjustment, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapGoalAdjustmentAdjuster: GoalAdjustmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGoalAdjustmentAdjuster: GoalAdjustmentStep {
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

        func adjust(_ item: GoalAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionGoalAdjustmentAdjuster: GoalAdjustmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: GoalAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingGoalAdjustmentAdjuster: GoalAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGoalAdjustmentAdjuster: GoalAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal adjustment steps in order and keeps a trace of each.
    final class GoalAdjustmentEngine {
        var steps: [any GoalAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GoalAdjustment) -> Double {
            var current = item.measuredValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [GoalAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGoalAdjustmentEngine(_ flags: Kit.Flags.Registry) -> GoalAdjustmentEngine {
        return GoalAdjustmentEngine(
            steps: [
                GoalAdjustmentQuantityOffsetAdjuster(weight: 0.23),
                CapGoalAdjustmentAdjuster(cap: 27232.0),
                FlaggedGoalAdjustmentAdjuster(flags: flags, flag: "goal-adjustment-default", percent: 6.7),
                RegionGoalAdjustmentAdjuster(factors: ["online": 0.96, "south": 1.0, "west": 1.26]),
                RoundingGoalAdjustmentAdjuster(step: 1.0),
                PercentGoalAdjustmentAdjuster(percent: 7.1),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 58548.9
        )
    }
}
