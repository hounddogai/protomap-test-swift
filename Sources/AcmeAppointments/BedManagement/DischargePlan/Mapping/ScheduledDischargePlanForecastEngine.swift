import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled discharge plan forecast calculation.
    protocol ScheduledDischargePlanForecastAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledDischargePlanForecast, value: Double) -> Double
    }

    final class RoundingScheduledDischargePlanForecastAdjuster: ScheduledDischargePlanForecastAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledDischargePlanForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredScheduledDischargePlanForecastAdjuster: ScheduledDischargePlanForecastAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledDischargePlanForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumScheduledDischargePlanForecastAdjuster: ScheduledDischargePlanForecastAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledDischargePlanForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled discharge plan forecast steps in order and keeps a trace of each.
    final class ScheduledDischargePlanForecastEngine {
        var steps: [any ScheduledDischargePlanForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledDischargePlanForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledDischargePlanForecast) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ScheduledDischargePlanForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledDischargePlanForecastEngine() -> ScheduledDischargePlanForecastEngine {
        return ScheduledDischargePlanForecastEngine(
            steps: [
                RoundingScheduledDischargePlanForecastAdjuster(step: 0.1),
                TieredScheduledDischargePlanForecastAdjuster(
                    bounds: [3010.0, 5836.0, 6162.0],
                    rates: [0.81, 0.97, 0.99]
                ),
                MinimumScheduledDischargePlanForecastAdjuster(minimum: 37.3),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 55952.8
        )
    }
}
