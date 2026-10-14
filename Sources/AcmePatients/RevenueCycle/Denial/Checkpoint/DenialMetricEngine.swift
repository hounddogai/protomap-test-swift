import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial metric calculation.
    protocol DenialMetricAdjuster {
        func describe() -> String
        func adjust(_ item: DenialMetric, value: Double) -> Double
    }

    final class MinimumDenialMetricAdjuster: DenialMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDenialMetricAdjuster: DenialMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDenialMetricAdjuster: DenialMetricAdjuster {
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

        func adjust(_ item: DenialMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDenialMetricAdjuster: DenialMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the denial metric steps in order and keeps a trace of each.
    final class DenialMetricEngine {
        var steps: [any DenialMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DenialMetric) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [DenialMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDenialMetricEngine(_ flags: Kit.Flags.Registry) -> DenialMetricEngine {
        return DenialMetricEngine(
            steps: [
                MinimumDenialMetricAdjuster(minimum: 42.0),
                CapDenialMetricAdjuster(cap: 13742.0),
                FlaggedDenialMetricAdjuster(flags: flags, flag: "denial-metric-fallback", percent: 7.5),
                TieredDenialMetricAdjuster(bounds: [3244.0, 3815.0, 7117.0], rates: [1.04, 0.83, 1.19]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 51535.6
        )
    }
}
