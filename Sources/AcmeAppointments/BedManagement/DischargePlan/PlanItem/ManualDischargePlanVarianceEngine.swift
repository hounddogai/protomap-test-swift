import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual discharge plan variance calculation.
    protocol ManualDischargePlanVarianceFactor {
        func describe() -> String
        func adjust(_ item: ManualDischargePlanVariance, value: Double) -> Double
    }

    final class PercentManualDischargePlanVarianceAdjuster: ManualDischargePlanVarianceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualDischargePlanVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualDischargePlanVarianceAdjuster: ManualDischargePlanVarianceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualDischargePlanVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredManualDischargePlanVarianceAdjuster: ManualDischargePlanVarianceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDischargePlanVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualDischargePlanVarianceAdjuster: ManualDischargePlanVarianceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualDischargePlanVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentManualDischargePlanVarianceAdjuster: ManualDischargePlanVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ManualDischargePlanVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedManualDischargePlanVarianceAdjuster: ManualDischargePlanVarianceFactor {
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

        func adjust(_ item: ManualDischargePlanVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual discharge plan variance steps in order and keeps a trace of each.
    final class ManualDischargePlanVarianceEngine {
        var steps: [any ManualDischargePlanVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDischargePlanVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualDischargePlanVariance) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualDischargePlanVarianceFactor = steps[index]
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

        func evaluateAll(_ items: [ManualDischargePlanVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualDischargePlanVarianceEngine(_ flags: Kit.Flags.Registry) -> ManualDischargePlanVarianceEngine {
        return ManualDischargePlanVarianceEngine(
            steps: [
                PercentManualDischargePlanVarianceAdjuster(percent: -12.1),
                CapManualDischargePlanVarianceAdjuster(cap: 9696.0),
                TieredManualDischargePlanVarianceAdjuster(bounds: [5745.0, 6823.0], rates: [0.81, 0.88]),
                RoundingManualDischargePlanVarianceAdjuster(step: 1.0),
                SegmentManualDischargePlanVarianceAdjuster(factors: ["retail": 0.9, "east": 0.97]),
                FlaggedManualDischargePlanVarianceAdjuster(
                    flags: flags,
                    flag: "manual-discharge-plan-variance-scheduled",
                    percent: -7.7
                ),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 23291.3
        )
    }
}
