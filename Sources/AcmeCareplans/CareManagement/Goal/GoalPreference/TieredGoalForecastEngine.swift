import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered goal forecast calculation.
    protocol TieredGoalForecastStep {
        func describe() -> String
        func adjust(_ item: TieredGoalForecast, value: Double) -> Double
    }

    final class RoundingTieredGoalForecastAdjuster: TieredGoalForecastStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredGoalForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredTieredGoalForecastAdjuster: TieredGoalForecastStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredGoalForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTieredGoalForecastAdjuster: TieredGoalForecastStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredGoalForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered goal forecast steps in order and keeps a trace of each.
    final class TieredGoalForecastEngine {
        var steps: [any TieredGoalForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredGoalForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredGoalForecast) -> Double {
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

        func evaluateAll(_ items: [TieredGoalForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredGoalForecastEngine() -> TieredGoalForecastEngine {
        return TieredGoalForecastEngine(
            steps: [
                RoundingTieredGoalForecastAdjuster(step: 0.25),
                TieredTieredGoalForecastAdjuster(bounds: [1421.0, 1842.0, 6324.0], rates: [0.92, 0.97, 0.92]),
                MinimumTieredGoalForecastAdjuster(minimum: 6.9),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 53362.6
        )
    }
}
