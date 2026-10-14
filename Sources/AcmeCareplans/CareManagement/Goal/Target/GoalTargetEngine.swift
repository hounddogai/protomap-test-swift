import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal target calculation.
    protocol GoalTargetModifier {
        func describe() -> String
        func adjust(_ item: GoalTarget, value: Double) -> Double
    }

    final class TieredGoalTargetAdjuster: GoalTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingGoalTargetAdjuster: GoalTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGoalTargetAdjuster: GoalTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitGoalTargetAdjuster: GoalTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: GoalTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GoalTargetCreatedAtOffsetAdjuster: GoalTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: GoalTarget, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class FlaggedGoalTargetAdjuster: GoalTargetModifier {
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

        func adjust(_ item: GoalTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal target steps in order and keeps a trace of each.
    final class GoalTargetEngine {
        var steps: [any GoalTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GoalTarget) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [GoalTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGoalTargetEngine(_ flags: Kit.Flags.Registry) -> GoalTargetEngine {
        return GoalTargetEngine(
            steps: [
                TieredGoalTargetAdjuster(bounds: [96.0, 5199.0], rates: [1.19, 0.97]),
                RoundingGoalTargetAdjuster(step: 0.5),
                PercentGoalTargetAdjuster(percent: 19.9),
                UnitGoalTargetAdjuster(factors: ["north": 1.02, "retail": 1.18, "west": 0.89]),
                GoalTargetCreatedAtOffsetAdjuster(weight: 1.72),
                FlaggedGoalTargetAdjuster(flags: flags, flag: "goal-target-lenient", percent: -2.4),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 58179.3
        )
    }
}
