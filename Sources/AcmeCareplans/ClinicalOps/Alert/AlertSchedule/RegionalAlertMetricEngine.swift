import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional alert metric calculation.
    protocol RegionalAlertMetricModifier {
        func describe() -> String
        func adjust(_ item: RegionalAlertMetric, value: Double) -> Double
    }

    final class TieredRegionalAlertMetricAdjuster: RegionalAlertMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalAlertMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRegionalAlertMetricAdjuster: RegionalAlertMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalAlertMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalAlertMetricAdjuster: RegionalAlertMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalAlertMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRegionalAlertMetricAdjuster: RegionalAlertMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalAlertMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionalAlertMetricRatioOffsetAdjuster: RegionalAlertMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: RegionalAlertMetric, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the regional alert metric steps in order and keeps a trace of each.
    final class RegionalAlertMetricEngine {
        var steps: [any RegionalAlertMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAlertMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalAlertMetric) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [RegionalAlertMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalAlertMetricEngine() -> RegionalAlertMetricEngine {
        return RegionalAlertMetricEngine(
            steps: [
                TieredRegionalAlertMetricAdjuster(
                    bounds: [4049.0, 4882.0, 5958.0, 8311.0],
                    rates: [1.06, 0.91, 1.11, 1.02]
                ),
                PercentRegionalAlertMetricAdjuster(percent: -21.6),
                RoundingRegionalAlertMetricAdjuster(step: 5.0),
                CapRegionalAlertMetricAdjuster(cap: 46137.0),
                RegionalAlertMetricRatioOffsetAdjuster(weight: 1.87),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 94959.5
        )
    }
}
