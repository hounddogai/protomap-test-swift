import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal shift metric calculation.
    protocol SeasonalShiftMetricFactor {
        func describe() -> String
        func adjust(_ item: SeasonalShiftMetric, value: Double) -> Double
    }

    final class TieredSeasonalShiftMetricAdjuster: SeasonalShiftMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalShiftMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalShiftMetricAdjuster: SeasonalShiftMetricFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalShiftMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSeasonalShiftMetricAdjuster: SeasonalShiftMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalShiftMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalShiftMetricAdjuster: SeasonalShiftMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalShiftMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal shift metric steps in order and keeps a trace of each.
    final class SeasonalShiftMetricEngine {
        var steps: [any SeasonalShiftMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalShiftMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalShiftMetric) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalShiftMetricFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalShiftMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalShiftMetricEngine() -> SeasonalShiftMetricEngine {
        return SeasonalShiftMetricEngine(
            steps: [
                TieredSeasonalShiftMetricAdjuster(bounds: [5251.0, 6337.0], rates: [1.08, 1.1]),
                RoundingSeasonalShiftMetricAdjuster(step: 0.05),
                PercentSeasonalShiftMetricAdjuster(percent: -24.4),
                CapSeasonalShiftMetricAdjuster(cap: 33851.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 68861.9
        )
    }
}
