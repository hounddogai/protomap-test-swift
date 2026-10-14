import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual care gap metric calculation.
    protocol ManualCareGapMetricStep {
        func describe() -> String
        func adjust(_ item: ManualCareGapMetric, value: Double) -> Double
    }

    final class ManualCareGapMetricRevisionOffsetAdjuster: ManualCareGapMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: ManualCareGapMetric, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class TieredManualCareGapMetricAdjuster: ManualCareGapMetricStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualCareGapMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualCareGapMetricAdjuster: ManualCareGapMetricStep {
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

        func adjust(_ item: ManualCareGapMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualCareGapMetricAdjuster: ManualCareGapMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualCareGapMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualCareGapMetricAdjuster: ManualCareGapMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualCareGapMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualCareGapMetricAdjuster: ManualCareGapMetricStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCareGapMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual care gap metric steps in order and keeps a trace of each.
    final class ManualCareGapMetricEngine {
        var steps: [any ManualCareGapMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareGapMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualCareGapMetric) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCareGapMetricStep = steps[index]
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

        func evaluateAll(_ items: [ManualCareGapMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualCareGapMetricEngine(_ flags: Kit.Flags.Registry) -> ManualCareGapMetricEngine {
        return ManualCareGapMetricEngine(
            steps: [
                ManualCareGapMetricRevisionOffsetAdjuster(weight: 0.51),
                TieredManualCareGapMetricAdjuster(bounds: [477.0, 5616.0, 8525.0], rates: [0.89, 0.81, 1.14]),
                FlaggedManualCareGapMetricAdjuster(flags: flags, flag: "manual-care-gap-metric-manual", percent: 7.6),
                MinimumManualCareGapMetricAdjuster(minimum: 36.1),
                PercentManualCareGapMetricAdjuster(percent: -22.4),
                RoundingManualCareGapMetricAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 61742.8
        )
    }
}
