import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient discharge plan quota calculation.
    protocol LenientDischargePlanQuotaStep {
        func describe() -> String
        func adjust(_ item: LenientDischargePlanQuota, value: Double) -> Double
    }

    final class FlaggedLenientDischargePlanQuotaAdjuster: LenientDischargePlanQuotaStep {
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

        func adjust(_ item: LenientDischargePlanQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientDischargePlanQuotaAdjuster: LenientDischargePlanQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientDischargePlanQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientDischargePlanQuotaAdjuster: LenientDischargePlanQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientDischargePlanQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLenientDischargePlanQuotaAdjuster: LenientDischargePlanQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientDischargePlanQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelLenientDischargePlanQuotaAdjuster: LenientDischargePlanQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientDischargePlanQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLenientDischargePlanQuotaAdjuster: LenientDischargePlanQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientDischargePlanQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient discharge plan quota steps in order and keeps a trace of each.
    final class LenientDischargePlanQuotaEngine {
        var steps: [any LenientDischargePlanQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientDischargePlanQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientDischargePlanQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientDischargePlanQuotaStep = steps[index]
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

        func evaluateAll(_ items: [LenientDischargePlanQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientDischargePlanQuotaEngine(_ flags: Kit.Flags.Registry) -> LenientDischargePlanQuotaEngine {
        return LenientDischargePlanQuotaEngine(
            steps: [
                FlaggedLenientDischargePlanQuotaAdjuster(
                    flags: flags,
                    flag: "lenient-discharge-plan-quota-fallback",
                    percent: 7.2
                ),
                MinimumLenientDischargePlanQuotaAdjuster(minimum: 39.5),
                TieredLenientDischargePlanQuotaAdjuster(
                    bounds: [2013.0, 3632.0, 4703.0, 8885.0],
                    rates: [0.87, 0.87, 1.02, 1.17]
                ),
                PercentLenientDischargePlanQuotaAdjuster(percent: 14.6),
                LabelLenientDischargePlanQuotaAdjuster(factors: ["west": 0.94, "south": 1.35]),
                RoundingLenientDischargePlanQuotaAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 99059.4
        )
    }
}
