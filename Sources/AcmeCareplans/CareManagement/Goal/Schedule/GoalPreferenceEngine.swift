import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal preference calculation.
    protocol GoalPreferenceFactor {
        func describe() -> String
        func adjust(_ item: GoalPreference, value: Double) -> Double
    }

    final class RoundingGoalPreferenceAdjuster: GoalPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapGoalPreferenceAdjuster: GoalPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredGoalPreferenceAdjuster: GoalPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GoalPreferenceFloorValueOffsetAdjuster: GoalPreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: GoalPreference, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class PercentGoalPreferenceAdjuster: GoalPreferenceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceGoalPreferenceAdjuster: GoalPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: GoalPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the goal preference steps in order and keeps a trace of each.
    final class GoalPreferenceEngine {
        var steps: [any GoalPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GoalPreference) -> Double {
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

        func evaluateAll(_ items: [GoalPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGoalPreferenceEngine() -> GoalPreferenceEngine {
        return GoalPreferenceEngine(
            steps: [
                RoundingGoalPreferenceAdjuster(step: 0.25),
                CapGoalPreferenceAdjuster(cap: 44504.0),
                TieredGoalPreferenceAdjuster(
                    bounds: [1663.0, 1946.0, 2834.0, 8265.0],
                    rates: [1.01, 1.05, 1.12, 1.14]
                ),
                GoalPreferenceFloorValueOffsetAdjuster(weight: 0.22),
                PercentGoalPreferenceAdjuster(percent: 14.5),
                SourceGoalPreferenceAdjuster(factors: ["central": 1.17, "south": 1.39, "north": 0.78]),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 18057.2
        )
    }
}
