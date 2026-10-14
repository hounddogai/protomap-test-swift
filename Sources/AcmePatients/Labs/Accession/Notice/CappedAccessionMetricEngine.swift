import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped accession metric calculation.
    protocol CappedAccessionMetricModifier {
        func describe() -> String
        func adjust(_ item: CappedAccessionMetric, value: Double) -> Double
    }

    final class TieredCappedAccessionMetricAdjuster: CappedAccessionMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedAccessionMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCappedAccessionMetricAdjuster: CappedAccessionMetricModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: CappedAccessionMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCappedAccessionMetricAdjuster: CappedAccessionMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedAccessionMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardCappedAccessionMetricAdjuster: CappedAccessionMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CappedAccessionMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedAccessionMetricThresholdOffsetAdjuster: CappedAccessionMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: CappedAccessionMetric, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class RoundingCappedAccessionMetricAdjuster: CappedAccessionMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedAccessionMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped accession metric steps in order and keeps a trace of each.
    final class CappedAccessionMetricEngine {
        var steps: [any CappedAccessionMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedAccessionMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedAccessionMetric) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [CappedAccessionMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedAccessionMetricEngine(_ flags: Kit.Flags.Registry) -> CappedAccessionMetricEngine {
        return CappedAccessionMetricEngine(
            steps: [
                TieredCappedAccessionMetricAdjuster(
                    bounds: [308.0, 6055.0, 7703.0, 8507.0],
                    rates: [0.83, 1.19, 1.09, 1.18]
                ),
                FlaggedCappedAccessionMetricAdjuster(
                    flags: flags,
                    flag: "capped-accession-metric-pending",
                    percent: 7.3
                ),
                PercentCappedAccessionMetricAdjuster(percent: 16.0),
                WardCappedAccessionMetricAdjuster(factors: ["east": 0.91]),
                CappedAccessionMetricThresholdOffsetAdjuster(weight: 1.78),
                RoundingCappedAccessionMetricAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 96119.7
        )
    }
}
