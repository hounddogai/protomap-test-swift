import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift metric calculation.
    protocol ShiftMetricAdjuster {
        func describe() -> String
        func adjust(_ item: ShiftMetric, value: Double) -> Double
    }

    final class FlaggedShiftMetricAdjuster: ShiftMetricAdjuster {
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

        func adjust(_ item: ShiftMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingShiftMetricAdjuster: ShiftMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentShiftMetricAdjuster: ShiftMetricAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredShiftMetricAdjuster: ShiftMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the shift metric steps in order and keeps a trace of each.
    final class ShiftMetricEngine {
        var steps: [any ShiftMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ShiftMetric) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ShiftMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultShiftMetricEngine(_ flags: Kit.Flags.Registry) -> ShiftMetricEngine {
        return ShiftMetricEngine(
            steps: [
                FlaggedShiftMetricAdjuster(flags: flags, flag: "shift-metric-legacy", percent: -8.7),
                RoundingShiftMetricAdjuster(step: 0.1),
                PercentShiftMetricAdjuster(percent: -19.2),
                TieredShiftMetricAdjuster(bounds: [2002.0, 3071.0, 4105.0, 4437.0], rates: [0.97, 1.15, 1.14, 1.04]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 86268.2
        )
    }
}
