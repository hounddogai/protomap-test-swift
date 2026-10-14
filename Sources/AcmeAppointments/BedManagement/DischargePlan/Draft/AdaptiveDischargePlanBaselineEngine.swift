import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive discharge plan baseline calculation.
    protocol AdaptiveDischargePlanBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveDischargePlanBaseline, value: Double) -> Double
    }

    final class TieredAdaptiveDischargePlanBaselineAdjuster: AdaptiveDischargePlanBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveDischargePlanBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAdaptiveDischargePlanBaselineAdjuster: AdaptiveDischargePlanBaselineAdjuster {
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

        func adjust(_ item: AdaptiveDischargePlanBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveDischargePlanBaselineAdjuster: AdaptiveDischargePlanBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveDischargePlanBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryAdaptiveDischargePlanBaselineAdjuster: AdaptiveDischargePlanBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AdaptiveDischargePlanBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAdaptiveDischargePlanBaselineAdjuster: AdaptiveDischargePlanBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveDischargePlanBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAdaptiveDischargePlanBaselineAdjuster: AdaptiveDischargePlanBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveDischargePlanBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive discharge plan baseline steps in order and keeps a trace of each.
    final class AdaptiveDischargePlanBaselineEngine {
        var steps: [any AdaptiveDischargePlanBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveDischargePlanBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveDischargePlanBaseline) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveDischargePlanBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveDischargePlanBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveDischargePlanBaselineEngine(_ flags: Kit.Flags.Registry) -> AdaptiveDischargePlanBaselineEngine {
        return AdaptiveDischargePlanBaselineEngine(
            steps: [
                TieredAdaptiveDischargePlanBaselineAdjuster(
                    bounds: [1435.0, 3106.0, 4627.0, 6329.0],
                    rates: [1.18, 1.0, 0.96, 1.13]
                ),
                FlaggedAdaptiveDischargePlanBaselineAdjuster(
                    flags: flags,
                    flag: "adaptive-discharge-plan-baseline-primary",
                    percent: 6.1
                ),
                PercentAdaptiveDischargePlanBaselineAdjuster(percent: 24.7),
                CountryAdaptiveDischargePlanBaselineAdjuster(factors: ["central": 1.28, "east": 1.27, "south": 0.83]),
                CapAdaptiveDischargePlanBaselineAdjuster(cap: 20513.0),
                MinimumAdaptiveDischargePlanBaselineAdjuster(minimum: 24.8),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 55769.2
        )
    }
}
