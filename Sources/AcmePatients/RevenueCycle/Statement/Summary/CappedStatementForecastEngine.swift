import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped statement forecast calculation.
    protocol CappedStatementForecastFactor {
        func describe() -> String
        func adjust(_ item: CappedStatementForecast, value: Double) -> Double
    }

    final class SegmentCappedStatementForecastAdjuster: CappedStatementForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: CappedStatementForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCappedStatementForecastAdjuster: CappedStatementForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedStatementForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedStatementForecastMaximumOffsetAdjuster: CappedStatementForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: CappedStatementForecast, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class TieredCappedStatementForecastAdjuster: CappedStatementForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedStatementForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped statement forecast steps in order and keeps a trace of each.
    final class CappedStatementForecastEngine {
        var steps: [any CappedStatementForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedStatementForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedStatementForecast) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedStatementForecastFactor = steps[index]
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

        func evaluateAll(_ items: [CappedStatementForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedStatementForecastEngine() -> CappedStatementForecastEngine {
        return CappedStatementForecastEngine(
            steps: [
                SegmentCappedStatementForecastAdjuster(factors: ["west": 0.88, "south": 1.11]),
                PercentCappedStatementForecastAdjuster(percent: -6.6),
                CappedStatementForecastMaximumOffsetAdjuster(weight: 0.56),
                TieredCappedStatementForecastAdjuster(bounds: [1456.0, 9098.0], rates: [1.06, 0.95]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 52768.5
        )
    }
}
