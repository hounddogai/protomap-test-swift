import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal forecast calculation.
    protocol GoalForecastFactor {
        func describe() -> String
        func adjust(_ item: GoalForecast, value: Double) -> Double
    }

    final class TieredGoalForecastAdjuster: GoalForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGoalForecastAdjuster: GoalForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GoalForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleGoalForecastAdjuster: GoalForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GoalForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGoalForecastAdjuster: GoalForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGoalForecastAdjuster: GoalForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedGoalForecastAdjuster: GoalForecastFactor {
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

        func adjust(_ item: GoalForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the goal forecast steps in order and keeps a trace of each.
    final class GoalForecastEngine {
        var steps: [any GoalForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GoalForecast) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GoalForecastFactor = steps[index]
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

        func evaluateAll(_ items: [GoalForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGoalForecastEngine(_ flags: Kit.Flags.Registry) -> GoalForecastEngine {
        return GoalForecastEngine(
            steps: [
                TieredGoalForecastAdjuster(bounds: [971.0, 1349.0, 2282.0], rates: [1.08, 0.91, 1.06]),
                MinimumGoalForecastAdjuster(minimum: 31.5),
                TitleGoalForecastAdjuster(factors: ["west": 1.14, "south": 1.39, "online": 1.19]),
                PercentGoalForecastAdjuster(percent: 21.0),
                RoundingGoalForecastAdjuster(step: 0.25),
                FlaggedGoalForecastAdjuster(flags: flags, flag: "goal-forecast-capped", percent: 3.9),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 78855.3
        )
    }
}
