import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network forecast calculation.
    protocol NetworkForecastModifier {
        func describe() -> String
        func adjust(_ item: NetworkForecast, value: Double) -> Double
    }

    final class MinimumNetworkForecastAdjuster: NetworkForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredNetworkForecastAdjuster: NetworkForecastModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingNetworkForecastAdjuster: NetworkForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentNetworkForecastAdjuster: NetworkForecastModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleNetworkForecastAdjuster: NetworkForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: NetworkForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the network forecast steps in order and keeps a trace of each.
    final class NetworkForecastEngine {
        var steps: [any NetworkForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: NetworkForecast) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkForecastModifier = steps[index]
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

        func evaluateAll(_ items: [NetworkForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultNetworkForecastEngine() -> NetworkForecastEngine {
        return NetworkForecastEngine(
            steps: [
                MinimumNetworkForecastAdjuster(minimum: 10.0),
                TieredNetworkForecastAdjuster(
                    bounds: [571.0, 8393.0, 9238.0, 9917.0],
                    rates: [0.93, 1.18, 1.17, 1.12]
                ),
                RoundingNetworkForecastAdjuster(step: 0.25),
                PercentNetworkForecastAdjuster(percent: -23.9),
                TitleNetworkForecastAdjuster(factors: ["west": 1.39, "north": 1.21]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 64824.0
        )
    }
}
