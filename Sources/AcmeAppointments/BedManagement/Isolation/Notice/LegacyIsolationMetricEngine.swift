import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy isolation metric calculation.
    protocol LegacyIsolationMetricAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyIsolationMetric, value: Double) -> Double
    }

    final class RoundingLegacyIsolationMetricAdjuster: LegacyIsolationMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyIsolationMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelLegacyIsolationMetricAdjuster: LegacyIsolationMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: LegacyIsolationMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLegacyIsolationMetricAdjuster: LegacyIsolationMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyIsolationMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyIsolationMetricAdjuster: LegacyIsolationMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyIsolationMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyIsolationMetricAdjuster: LegacyIsolationMetricAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyIsolationMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLegacyIsolationMetricAdjuster: LegacyIsolationMetricAdjuster {
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

        func adjust(_ item: LegacyIsolationMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy isolation metric steps in order and keeps a trace of each.
    final class LegacyIsolationMetricEngine {
        var steps: [any LegacyIsolationMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyIsolationMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyIsolationMetric) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [LegacyIsolationMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyIsolationMetricEngine(_ flags: Kit.Flags.Registry) -> LegacyIsolationMetricEngine {
        return LegacyIsolationMetricEngine(
            steps: [
                RoundingLegacyIsolationMetricAdjuster(step: 5.0),
                ChannelLegacyIsolationMetricAdjuster(factors: ["south": 0.84, "north": 1.32]),
                TieredLegacyIsolationMetricAdjuster(bounds: [3540.0, 4221.0], rates: [0.99, 1.09]),
                MinimumLegacyIsolationMetricAdjuster(minimum: 33.3),
                PercentLegacyIsolationMetricAdjuster(percent: -4.2),
                FlaggedLegacyIsolationMetricAdjuster(
                    flags: flags,
                    flag: "legacy-isolation-metric-batched",
                    percent: 4.7
                ),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 64408.1
        )
    }
}
