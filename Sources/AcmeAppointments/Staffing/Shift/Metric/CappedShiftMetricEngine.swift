import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the capped shift metric calculation.
    protocol CappedShiftMetricAdjuster {
        func describe() -> String
        func adjust(_ item: CappedShiftMetric, value: Double) -> Double
    }

    final class CappedShiftMetricSequenceOffsetAdjuster: CappedShiftMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: CappedShiftMetric, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class CapCappedShiftMetricAdjuster: CappedShiftMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedShiftMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCappedShiftMetricAdjuster: CappedShiftMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedShiftMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCappedShiftMetricAdjuster: CappedShiftMetricAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedShiftMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCappedShiftMetricAdjuster: CappedShiftMetricAdjuster {
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

        func adjust(_ item: CappedShiftMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedShiftMetricAdjuster: CappedShiftMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedShiftMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped shift metric steps in order and keeps a trace of each.
    final class CappedShiftMetricEngine {
        var steps: [any CappedShiftMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedShiftMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedShiftMetric) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedShiftMetricAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedShiftMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedShiftMetricEngine(_ flags: Kit.Flags.Registry) -> CappedShiftMetricEngine {
        return CappedShiftMetricEngine(
            steps: [
                CappedShiftMetricSequenceOffsetAdjuster(weight: 0.01),
                CapCappedShiftMetricAdjuster(cap: 12088.0),
                RoundingCappedShiftMetricAdjuster(step: 1.0),
                PercentCappedShiftMetricAdjuster(percent: -22.0),
                FlaggedCappedShiftMetricAdjuster(flags: flags, flag: "capped-shift-metric-primary", percent: -7.5),
                MinimumCappedShiftMetricAdjuster(minimum: 21.1),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 24221.9
        )
    }
}
