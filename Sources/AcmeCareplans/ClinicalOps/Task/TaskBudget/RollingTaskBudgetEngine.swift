import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rolling task budget calculation.
    protocol RollingTaskBudgetModifier {
        func describe() -> String
        func adjust(_ item: RollingTaskBudget, value: Double) -> Double
    }

    final class MinimumRollingTaskBudgetAdjuster: RollingTaskBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingTaskBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingTaskBudgetAdjuster: RollingTaskBudgetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingTaskBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRollingTaskBudgetAdjuster: RollingTaskBudgetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingTaskBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingTaskBudgetCreatedAtOffsetAdjuster: RollingTaskBudgetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: RollingTaskBudget, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class FlaggedRollingTaskBudgetAdjuster: RollingTaskBudgetModifier {
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

        func adjust(_ item: RollingTaskBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRollingTaskBudgetAdjuster: RollingTaskBudgetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingTaskBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling task budget steps in order and keeps a trace of each.
    final class RollingTaskBudgetEngine {
        var steps: [any RollingTaskBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingTaskBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingTaskBudget) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [RollingTaskBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingTaskBudgetEngine(_ flags: Kit.Flags.Registry) -> RollingTaskBudgetEngine {
        return RollingTaskBudgetEngine(
            steps: [
                MinimumRollingTaskBudgetAdjuster(minimum: 43.5),
                TieredRollingTaskBudgetAdjuster(bounds: [56.0, 6952.0], rates: [1.08, 1.19]),
                RoundingRollingTaskBudgetAdjuster(step: 0.25),
                RollingTaskBudgetCreatedAtOffsetAdjuster(weight: 0.12),
                FlaggedRollingTaskBudgetAdjuster(flags: flags, flag: "rolling-task-budget-lenient", percent: 2.3),
                PercentRollingTaskBudgetAdjuster(percent: -13.7),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 31842.1
        )
    }
}
