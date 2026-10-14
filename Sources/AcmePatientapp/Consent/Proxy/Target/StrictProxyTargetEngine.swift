import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict proxy target calculation.
    protocol StrictProxyTargetModifier {
        func describe() -> String
        func adjust(_ item: StrictProxyTarget, value: Double) -> Double
    }

    final class TieredStrictProxyTargetAdjuster: StrictProxyTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictProxyTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStrictProxyTargetAdjuster: StrictProxyTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictProxyTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictProxyTargetAdjuster: StrictProxyTargetModifier {
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

        func adjust(_ item: StrictProxyTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelStrictProxyTargetAdjuster: StrictProxyTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictProxyTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStrictProxyTargetAdjuster: StrictProxyTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictProxyTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStrictProxyTargetAdjuster: StrictProxyTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictProxyTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict proxy target steps in order and keeps a trace of each.
    final class StrictProxyTargetEngine {
        var steps: [any StrictProxyTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictProxyTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictProxyTarget) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictProxyTargetModifier = steps[index]
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

        func evaluateAll(_ items: [StrictProxyTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictProxyTargetEngine(_ flags: Kit.Flags.Registry) -> StrictProxyTargetEngine {
        return StrictProxyTargetEngine(
            steps: [
                TieredStrictProxyTargetAdjuster(bounds: [3330.0, 5128.0, 7219.0], rates: [1.13, 1.05, 1.09]),
                RoundingStrictProxyTargetAdjuster(step: 1.0),
                FlaggedStrictProxyTargetAdjuster(flags: flags, flag: "strict-proxy-target-global", percent: 1.0),
                LabelStrictProxyTargetAdjuster(factors: ["retail": 0.92]),
                MinimumStrictProxyTargetAdjuster(minimum: 45.8),
                PercentStrictProxyTargetAdjuster(percent: 17.6),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 97815.9
        )
    }
}
