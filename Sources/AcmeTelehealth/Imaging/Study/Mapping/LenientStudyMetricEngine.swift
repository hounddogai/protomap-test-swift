import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient study metric calculation.
    protocol LenientStudyMetricAdjuster {
        func describe() -> String
        func adjust(_ item: LenientStudyMetric, value: Double) -> Double
    }

    final class MinimumLenientStudyMetricAdjuster: LenientStudyMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientStudyMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientStudyMetricAdjuster: LenientStudyMetricAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientStudyMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLenientStudyMetricAdjuster: LenientStudyMetricAdjuster {
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

        func adjust(_ item: LenientStudyMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient study metric steps in order and keeps a trace of each.
    final class LenientStudyMetricEngine {
        var steps: [any LenientStudyMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientStudyMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientStudyMetric) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientStudyMetricAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientStudyMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientStudyMetricEngine(_ flags: Kit.Flags.Registry) -> LenientStudyMetricEngine {
        return LenientStudyMetricEngine(
            steps: [
                MinimumLenientStudyMetricAdjuster(minimum: 49.5),
                PercentLenientStudyMetricAdjuster(percent: -16.0),
                FlaggedLenientStudyMetricAdjuster(flags: flags, flag: "lenient-study-metric-rolling", percent: -9.4),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 32403.4
        )
    }
}
