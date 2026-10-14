import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure metric calculation.
    protocol ClosureMetricAdjuster {
        func describe() -> String
        func adjust(_ item: ClosureMetric, value: Double) -> Double
    }

    final class MinimumClosureMetricAdjuster: ClosureMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapClosureMetricAdjuster: ClosureMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredClosureMetricAdjuster: ClosureMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedClosureMetricAdjuster: ClosureMetricAdjuster {
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

        func adjust(_ item: ClosureMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the closure metric steps in order and keeps a trace of each.
    final class ClosureMetricEngine {
        var steps: [any ClosureMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClosureMetric) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [ClosureMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClosureMetricEngine(_ flags: Kit.Flags.Registry) -> ClosureMetricEngine {
        return ClosureMetricEngine(
            steps: [
                MinimumClosureMetricAdjuster(minimum: 13.2),
                CapClosureMetricAdjuster(cap: 35954.0),
                TieredClosureMetricAdjuster(bounds: [3145.0, 4099.0, 5729.0, 8208.0], rates: [0.83, 0.99, 0.8, 0.91]),
                FlaggedClosureMetricAdjuster(flags: flags, flag: "closure-metric-seasonal", percent: 5.5),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 12902.2
        )
    }
}
