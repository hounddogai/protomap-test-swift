import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient interaction forecast calculation.
    protocol LenientInteractionForecastAdjuster {
        func describe() -> String
        func adjust(_ item: LenientInteractionForecast, value: Double) -> Double
    }

    final class MinimumLenientInteractionForecastAdjuster: LenientInteractionForecastAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientInteractionForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientInteractionForecastAdjuster: LenientInteractionForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientInteractionForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionLenientInteractionForecastAdjuster: LenientInteractionForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: LenientInteractionForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLenientInteractionForecastAdjuster: LenientInteractionForecastAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientInteractionForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient interaction forecast steps in order and keeps a trace of each.
    final class LenientInteractionForecastEngine {
        var steps: [any LenientInteractionForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientInteractionForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientInteractionForecast) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [LenientInteractionForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientInteractionForecastEngine() -> LenientInteractionForecastEngine {
        return LenientInteractionForecastEngine(
            steps: [
                MinimumLenientInteractionForecastAdjuster(minimum: 29.7),
                PercentLenientInteractionForecastAdjuster(percent: 0.2),
                RegionLenientInteractionForecastAdjuster(factors: ["east": 1.06]),
                CapLenientInteractionForecastAdjuster(cap: 9648.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 8205.5
        )
    }
}
