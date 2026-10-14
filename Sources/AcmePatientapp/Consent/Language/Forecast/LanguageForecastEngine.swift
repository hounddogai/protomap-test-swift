import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language forecast calculation.
    protocol LanguageForecastModifier {
        func describe() -> String
        func adjust(_ item: LanguageForecast, value: Double) -> Double
    }

    final class MinimumLanguageForecastAdjuster: LanguageForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLanguageForecastAdjuster: LanguageForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLanguageForecastAdjuster: LanguageForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLanguageForecastAdjuster: LanguageForecastModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameLanguageForecastAdjuster: LanguageForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LanguageForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the language forecast steps in order and keeps a trace of each.
    final class LanguageForecastEngine {
        var steps: [any LanguageForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageForecast) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [LanguageForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageForecastEngine() -> LanguageForecastEngine {
        return LanguageForecastEngine(
            steps: [
                MinimumLanguageForecastAdjuster(minimum: 13.3),
                CapLanguageForecastAdjuster(cap: 21698.0),
                RoundingLanguageForecastAdjuster(step: 0.5),
                TieredLanguageForecastAdjuster(
                    bounds: [6991.0, 7553.0, 9057.0, 9728.0],
                    rates: [0.8, 1.0, 0.92, 1.04]
                ),
                NameLanguageForecastAdjuster(factors: ["west": 1.3, "east": 1.22, "central": 1.13]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 49166.3
        )
    }
}
