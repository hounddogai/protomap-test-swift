import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal study metric calculation.
    protocol SeasonalStudyMetricModifier {
        func describe() -> String
        func adjust(_ item: SeasonalStudyMetric, value: Double) -> Double
    }

    final class MinimumSeasonalStudyMetricAdjuster: SeasonalStudyMetricModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalStudyMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSeasonalStudyMetricAdjuster: SeasonalStudyMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalStudyMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSeasonalStudyMetricAdjuster: SeasonalStudyMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalStudyMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal study metric steps in order and keeps a trace of each.
    final class SeasonalStudyMetricEngine {
        var steps: [any SeasonalStudyMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalStudyMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalStudyMetric) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [SeasonalStudyMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalStudyMetricEngine() -> SeasonalStudyMetricEngine {
        return SeasonalStudyMetricEngine(
            steps: [
                MinimumSeasonalStudyMetricAdjuster(minimum: 35.8),
                TieredSeasonalStudyMetricAdjuster(bounds: [1966.0, 3622.0, 6793.0], rates: [0.84, 1.09, 1.02]),
                PercentSeasonalStudyMetricAdjuster(percent: 0.3),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 44645.1
        )
    }
}
