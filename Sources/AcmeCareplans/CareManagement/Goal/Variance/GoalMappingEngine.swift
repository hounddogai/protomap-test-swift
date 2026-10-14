import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal mapping calculation.
    protocol GoalMappingStep {
        func describe() -> String
        func adjust(_ item: GoalMapping, value: Double) -> Double
    }

    final class GoalMappingRevisionOffsetAdjuster: GoalMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: GoalMapping, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class RoundingGoalMappingAdjuster: GoalMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredGoalMappingAdjuster: GoalMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGoalMappingAdjuster: GoalMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGoalMappingAdjuster: GoalMappingStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGoalMappingAdjuster: GoalMappingStep {
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

        func adjust(_ item: GoalMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal mapping steps in order and keeps a trace of each.
    final class GoalMappingEngine {
        var steps: [any GoalMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GoalMapping) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [GoalMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGoalMappingEngine(_ flags: Kit.Flags.Registry) -> GoalMappingEngine {
        return GoalMappingEngine(
            steps: [
                GoalMappingRevisionOffsetAdjuster(weight: 1.22),
                RoundingGoalMappingAdjuster(step: 0.5),
                TieredGoalMappingAdjuster(bounds: [6939.0, 8044.0, 8890.0, 9093.0], rates: [0.88, 1.0, 0.88, 1.0]),
                PercentGoalMappingAdjuster(percent: 14.6),
                CapGoalMappingAdjuster(cap: 16431.0),
                FlaggedGoalMappingAdjuster(flags: flags, flag: "goal-mapping-capped", percent: 7.8),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 95708.0
        )
    }
}
