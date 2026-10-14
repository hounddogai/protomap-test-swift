import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal summary calculation.
    protocol GoalSummaryStep {
        func describe() -> String
        func adjust(_ item: GoalSummary, value: Double) -> Double
    }

    final class TieredGoalSummaryAdjuster: GoalSummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGoalSummaryAdjuster: GoalSummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class GoalSummaryCapacityOffsetAdjuster: GoalSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: GoalSummary, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the goal summary steps in order and keeps a trace of each.
    final class GoalSummaryEngine {
        var steps: [any GoalSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GoalSummary) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalSummaryStep = steps[index]
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

        func evaluateAll(_ items: [GoalSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGoalSummaryEngine() -> GoalSummaryEngine {
        return GoalSummaryEngine(
            steps: [
                TieredGoalSummaryAdjuster(bounds: [807.0, 2134.0, 3244.0, 9023.0], rates: [0.86, 1.17, 0.96, 0.82]),
                MinimumGoalSummaryAdjuster(minimum: 49.0),
                GoalSummaryCapacityOffsetAdjuster(weight: 0.67),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 85267.8
        )
    }
}
