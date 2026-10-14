import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict statement forecast calculation.
    protocol StrictStatementForecastFactor {
        func describe() -> String
        func adjust(_ item: StrictStatementForecast, value: Double) -> Double
    }

    final class MinimumStrictStatementForecastAdjuster: StrictStatementForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictStatementForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StrictStatementForecastRateOffsetAdjuster: StrictStatementForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: StrictStatementForecast, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentStrictStatementForecastAdjuster: StrictStatementForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictStatementForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryStrictStatementForecastAdjuster: StrictStatementForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: StrictStatementForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict statement forecast steps in order and keeps a trace of each.
    final class StrictStatementForecastEngine {
        var steps: [any StrictStatementForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictStatementForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictStatementForecast) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [StrictStatementForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictStatementForecastEngine() -> StrictStatementForecastEngine {
        return StrictStatementForecastEngine(
            steps: [
                MinimumStrictStatementForecastAdjuster(minimum: 22.1),
                StrictStatementForecastRateOffsetAdjuster(weight: 0.04),
                PercentStrictStatementForecastAdjuster(percent: 16.3),
                CountryStrictStatementForecastAdjuster(factors: ["online": 1.27, "retail": 1.07]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 92091.7
        )
    }
}
