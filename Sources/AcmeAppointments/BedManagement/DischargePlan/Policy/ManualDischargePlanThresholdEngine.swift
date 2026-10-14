import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual discharge plan threshold calculation.
    protocol ManualDischargePlanThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: ManualDischargePlanThreshold, value: Double) -> Double
    }

    final class TieredManualDischargePlanThresholdAdjuster: ManualDischargePlanThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDischargePlanThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualDischargePlanThresholdAdjuster: ManualDischargePlanThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualDischargePlanThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedManualDischargePlanThresholdAdjuster: ManualDischargePlanThresholdAdjuster {
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

        func adjust(_ item: ManualDischargePlanThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual discharge plan threshold steps in order and keeps a trace of each.
    final class ManualDischargePlanThresholdEngine {
        var steps: [any ManualDischargePlanThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDischargePlanThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualDischargePlanThreshold) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualDischargePlanThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualDischargePlanThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualDischargePlanThresholdEngine(_ flags: Kit.Flags.Registry) -> ManualDischargePlanThresholdEngine {
        return ManualDischargePlanThresholdEngine(
            steps: [
                TieredManualDischargePlanThresholdAdjuster(bounds: [1501.0, 1972.0], rates: [0.93, 0.94]),
                RoundingManualDischargePlanThresholdAdjuster(step: 0.05),
                FlaggedManualDischargePlanThresholdAdjuster(
                    flags: flags,
                    flag: "manual-discharge-plan-threshold-weighted",
                    percent: 5.8
                ),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 24802.1
        )
    }
}
