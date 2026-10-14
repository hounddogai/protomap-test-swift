import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback rounding metric calculation.
    protocol FallbackRoundingMetricAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackRoundingMetric, value: Double) -> Double
    }

    final class TieredFallbackRoundingMetricAdjuster: FallbackRoundingMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackRoundingMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFallbackRoundingMetricAdjuster: FallbackRoundingMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackRoundingMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFallbackRoundingMetricAdjuster: FallbackRoundingMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackRoundingMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackRoundingMetricStartsAtOffsetAdjuster: FallbackRoundingMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: FallbackRoundingMetric, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class NameFallbackRoundingMetricAdjuster: FallbackRoundingMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackRoundingMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedFallbackRoundingMetricAdjuster: FallbackRoundingMetricAdjuster {
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

        func adjust(_ item: FallbackRoundingMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback rounding metric steps in order and keeps a trace of each.
    final class FallbackRoundingMetricEngine {
        var steps: [any FallbackRoundingMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackRoundingMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackRoundingMetric) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackRoundingMetricAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackRoundingMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackRoundingMetricEngine(_ flags: Kit.Flags.Registry) -> FallbackRoundingMetricEngine {
        return FallbackRoundingMetricEngine(
            steps: [
                TieredFallbackRoundingMetricAdjuster(bounds: [5512.0, 8862.0], rates: [1.07, 0.91]),
                MinimumFallbackRoundingMetricAdjuster(minimum: 42.8),
                RoundingFallbackRoundingMetricAdjuster(step: 1.0),
                FallbackRoundingMetricStartsAtOffsetAdjuster(weight: 1.29),
                NameFallbackRoundingMetricAdjuster(factors: ["east": 0.88]),
                FlaggedFallbackRoundingMetricAdjuster(
                    flags: flags,
                    flag: "fallback-rounding-metric-adaptive",
                    percent: -5.2
                ),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 56994.9
        )
    }
}
