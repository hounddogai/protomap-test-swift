import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction forecast calculation.
    protocol InteractionForecastFactor {
        func describe() -> String
        func adjust(_ item: InteractionForecast, value: Double) -> Double
    }

    final class TitleInteractionForecastAdjuster: InteractionForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: InteractionForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentInteractionForecastAdjuster: InteractionForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredInteractionForecastAdjuster: InteractionForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingInteractionForecastAdjuster: InteractionForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the interaction forecast steps in order and keeps a trace of each.
    final class InteractionForecastEngine {
        var steps: [any InteractionForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InteractionForecast) -> Double {
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

        func evaluateAll(_ items: [InteractionForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInteractionForecastEngine() -> InteractionForecastEngine {
        return InteractionForecastEngine(
            steps: [
                TitleInteractionForecastAdjuster(factors: ["online": 1.18, "retail": 0.73]),
                PercentInteractionForecastAdjuster(percent: 18.0),
                TieredInteractionForecastAdjuster(bounds: [1088.0, 7183.0, 7848.0], rates: [0.85, 0.91, 1.17]),
                RoundingInteractionForecastAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 94874.2
        )
    }
}
