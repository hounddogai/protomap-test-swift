import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal closure metric calculation.
    protocol SeasonalClosureMetricStep {
        func describe() -> String
        func adjust(_ item: SeasonalClosureMetric, value: Double) -> Double
    }

    final class PercentSeasonalClosureMetricAdjuster: SeasonalClosureMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalClosureMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalClosureMetricAdjuster: SeasonalClosureMetricStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalClosureMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSeasonalClosureMetricAdjuster: SeasonalClosureMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalClosureMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal closure metric steps in order and keeps a trace of each.
    final class SeasonalClosureMetricEngine {
        var steps: [any SeasonalClosureMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalClosureMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalClosureMetric) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [SeasonalClosureMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalClosureMetricEngine() -> SeasonalClosureMetricEngine {
        return SeasonalClosureMetricEngine(
            steps: [
                PercentSeasonalClosureMetricAdjuster(percent: 17.6),
                TieredSeasonalClosureMetricAdjuster(
                    bounds: [429.0, 1765.0, 4736.0, 6204.0],
                    rates: [1.01, 1.01, 1.1, 0.97]
                ),
                MinimumSeasonalClosureMetricAdjuster(minimum: 43.6),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 7782.9
        )
    }
}
