import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure forecast calculation.
    protocol DisclosureForecastAdjuster {
        func describe() -> String
        func adjust(_ item: DisclosureForecast, value: Double) -> Double
    }

    final class PercentDisclosureForecastAdjuster: DisclosureForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryDisclosureForecastAdjuster: DisclosureForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: DisclosureForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDisclosureForecastAdjuster: DisclosureForecastAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the disclosure forecast steps in order and keeps a trace of each.
    final class DisclosureForecastEngine {
        var steps: [any DisclosureForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DisclosureForecast) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [DisclosureForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDisclosureForecastEngine() -> DisclosureForecastEngine {
        return DisclosureForecastEngine(
            steps: [
                PercentDisclosureForecastAdjuster(percent: -6.7),
                CategoryDisclosureForecastAdjuster(factors: ["west": 1.3]),
                RoundingDisclosureForecastAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 80637.8
        )
    }
}
