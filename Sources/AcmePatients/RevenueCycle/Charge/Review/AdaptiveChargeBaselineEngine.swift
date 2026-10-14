import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive charge baseline calculation.
    protocol AdaptiveChargeBaselineStep {
        func describe() -> String
        func adjust(_ item: AdaptiveChargeBaseline, value: Double) -> Double
    }

    final class MinimumAdaptiveChargeBaselineAdjuster: AdaptiveChargeBaselineStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveChargeBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveChargeBaselineAdjuster: AdaptiveChargeBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveChargeBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAdaptiveChargeBaselineAdjuster: AdaptiveChargeBaselineStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveChargeBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameAdaptiveChargeBaselineAdjuster: AdaptiveChargeBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveChargeBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAdaptiveChargeBaselineAdjuster: AdaptiveChargeBaselineStep {
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

        func adjust(_ item: AdaptiveChargeBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveChargeBaselineAdjuster: AdaptiveChargeBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveChargeBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive charge baseline steps in order and keeps a trace of each.
    final class AdaptiveChargeBaselineEngine {
        var steps: [any AdaptiveChargeBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveChargeBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveChargeBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveChargeBaselineStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveChargeBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveChargeBaselineEngine(_ flags: Kit.Flags.Registry) -> AdaptiveChargeBaselineEngine {
        return AdaptiveChargeBaselineEngine(
            steps: [
                MinimumAdaptiveChargeBaselineAdjuster(minimum: 46.4),
                TieredAdaptiveChargeBaselineAdjuster(bounds: [2471.0, 3436.0, 3586.0], rates: [0.99, 0.86, 0.97]),
                RoundingAdaptiveChargeBaselineAdjuster(step: 0.05),
                NameAdaptiveChargeBaselineAdjuster(factors: ["retail": 1.33]),
                FlaggedAdaptiveChargeBaselineAdjuster(
                    flags: flags,
                    flag: "adaptive-charge-baseline-strict",
                    percent: -6.7
                ),
                CapAdaptiveChargeBaselineAdjuster(cap: 45488.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 18574.8
        )
    }
}
