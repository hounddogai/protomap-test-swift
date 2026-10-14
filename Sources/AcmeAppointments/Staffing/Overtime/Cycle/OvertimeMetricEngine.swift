import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime metric calculation.
    protocol OvertimeMetricFactor {
        func describe() -> String
        func adjust(_ item: OvertimeMetric, value: Double) -> Double
    }

    final class CapOvertimeMetricAdjuster: OvertimeMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredOvertimeMetricAdjuster: OvertimeMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentOvertimeMetricAdjuster: OvertimeMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedOvertimeMetricAdjuster: OvertimeMetricFactor {
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

        func adjust(_ item: OvertimeMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOvertimeMetricAdjuster: OvertimeMetricFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class OvertimeMetricDosageMgOffsetAdjuster: OvertimeMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: OvertimeMetric, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the overtime metric steps in order and keeps a trace of each.
    final class OvertimeMetricEngine {
        var steps: [any OvertimeMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeMetric) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [OvertimeMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeMetricEngine(_ flags: Kit.Flags.Registry) -> OvertimeMetricEngine {
        return OvertimeMetricEngine(
            steps: [
                CapOvertimeMetricAdjuster(cap: 48246.0),
                TieredOvertimeMetricAdjuster(
                    bounds: [2372.0, 2818.0, 4037.0, 8717.0],
                    rates: [0.91, 1.19, 1.13, 1.15]
                ),
                PercentOvertimeMetricAdjuster(percent: -22.4),
                FlaggedOvertimeMetricAdjuster(flags: flags, flag: "overtime-metric-global", percent: 1.2),
                RoundingOvertimeMetricAdjuster(step: 0.05),
                OvertimeMetricDosageMgOffsetAdjuster(weight: 1.83),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 34906.0
        )
    }
}
