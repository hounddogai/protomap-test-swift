import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal baseline calculation.
    protocol GoalBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: GoalBaseline, value: Double) -> Double
    }

    final class SegmentGoalBaselineAdjuster: GoalBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: GoalBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedGoalBaselineAdjuster: GoalBaselineAdjuster {
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

        func adjust(_ item: GoalBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGoalBaselineAdjuster: GoalBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the goal baseline steps in order and keeps a trace of each.
    final class GoalBaselineEngine {
        var steps: [any GoalBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GoalBaseline) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [GoalBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGoalBaselineEngine(_ flags: Kit.Flags.Registry) -> GoalBaselineEngine {
        return GoalBaselineEngine(
            steps: [
                SegmentGoalBaselineAdjuster(factors: ["south": 1.34, "north": 0.96, "central": 1.09]),
                FlaggedGoalBaselineAdjuster(flags: flags, flag: "goal-baseline-legacy", percent: -8.8),
                TieredGoalBaselineAdjuster(bounds: [2015.0, 3765.0], rates: [1.14, 0.86]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 18863.4
        )
    }
}
