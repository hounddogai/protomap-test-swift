import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal denial metric calculation.
    protocol SeasonalDenialMetricModifier {
        func describe() -> String
        func adjust(_ item: SeasonalDenialMetric, value: Double) -> Double
    }

    final class SeasonalDenialMetricWeightOffsetAdjuster: SeasonalDenialMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: SeasonalDenialMetric, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredSeasonalDenialMetricAdjuster: SeasonalDenialMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalDenialMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalDenialMetricAdjuster: SeasonalDenialMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalDenialMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSeasonalDenialMetricAdjuster: SeasonalDenialMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalDenialMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleSeasonalDenialMetricAdjuster: SeasonalDenialMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalDenialMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSeasonalDenialMetricAdjuster: SeasonalDenialMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalDenialMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal denial metric steps in order and keeps a trace of each.
    final class SeasonalDenialMetricEngine {
        var steps: [any SeasonalDenialMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalDenialMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalDenialMetric) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [SeasonalDenialMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalDenialMetricEngine() -> SeasonalDenialMetricEngine {
        return SeasonalDenialMetricEngine(
            steps: [
                SeasonalDenialMetricWeightOffsetAdjuster(weight: 0.5),
                TieredSeasonalDenialMetricAdjuster(bounds: [1968.0, 5734.0, 9318.0], rates: [1.18, 1.06, 0.98]),
                RoundingSeasonalDenialMetricAdjuster(step: 0.5),
                PercentSeasonalDenialMetricAdjuster(percent: 18.3),
                TitleSeasonalDenialMetricAdjuster(factors: ["west": 1.02, "east": 1.26, "central": 1.26]),
                CapSeasonalDenialMetricAdjuster(cap: 30783.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 69114.9
        )
    }
}
