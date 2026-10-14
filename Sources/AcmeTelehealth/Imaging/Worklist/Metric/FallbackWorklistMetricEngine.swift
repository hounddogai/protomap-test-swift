import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback worklist metric calculation.
    protocol FallbackWorklistMetricFactor {
        func describe() -> String
        func adjust(_ item: FallbackWorklistMetric, value: Double) -> Double
    }

    final class SourceFallbackWorklistMetricAdjuster: FallbackWorklistMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FallbackWorklistMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackWorklistMetricAdjuster: FallbackWorklistMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackWorklistMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackWorklistMetricCostOffsetAdjuster: FallbackWorklistMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: FallbackWorklistMetric, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the fallback worklist metric steps in order and keeps a trace of each.
    final class FallbackWorklistMetricEngine {
        var steps: [any FallbackWorklistMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackWorklistMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackWorklistMetric) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackWorklistMetricFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackWorklistMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackWorklistMetricEngine() -> FallbackWorklistMetricEngine {
        return FallbackWorklistMetricEngine(
            steps: [
                SourceFallbackWorklistMetricAdjuster(factors: ["west": 1.39, "central": 1.25, "retail": 0.81]),
                TieredFallbackWorklistMetricAdjuster(bounds: [332.0, 4780.0], rates: [0.89, 1.19]),
                FallbackWorklistMetricCostOffsetAdjuster(weight: 0.33),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 86529.6
        )
    }
}
