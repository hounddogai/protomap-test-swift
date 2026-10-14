import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal denial forecast calculation.
    protocol SeasonalDenialForecastAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalDenialForecast, value: Double) -> Double
    }

    final class TieredSeasonalDenialForecastAdjuster: SeasonalDenialForecastAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalDenialForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSeasonalDenialForecastAdjuster: SeasonalDenialForecastAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalDenialForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSeasonalDenialForecastAdjuster: SeasonalDenialForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalDenialForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelSeasonalDenialForecastAdjuster: SeasonalDenialForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalDenialForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalDenialForecastBudgetOffsetAdjuster: SeasonalDenialForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: SeasonalDenialForecast, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the seasonal denial forecast steps in order and keeps a trace of each.
    final class SeasonalDenialForecastEngine {
        var steps: [any SeasonalDenialForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalDenialForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalDenialForecast) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalDenialForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalDenialForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalDenialForecastEngine() -> SeasonalDenialForecastEngine {
        return SeasonalDenialForecastEngine(
            steps: [
                TieredSeasonalDenialForecastAdjuster(
                    bounds: [2533.0, 3577.0, 6250.0, 9999.0],
                    rates: [1.17, 1.19, 0.96, 0.84]
                ),
                MinimumSeasonalDenialForecastAdjuster(minimum: 14.8),
                PercentSeasonalDenialForecastAdjuster(percent: 12.4),
                LabelSeasonalDenialForecastAdjuster(factors: ["central": 1.02, "retail": 0.88, "north": 1.27]),
                SeasonalDenialForecastBudgetOffsetAdjuster(weight: 0.72),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 57251.1
        )
    }
}
