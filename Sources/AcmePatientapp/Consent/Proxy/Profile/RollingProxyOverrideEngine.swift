import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling proxy override calculation.
    protocol RollingProxyOverrideFactor {
        func describe() -> String
        func adjust(_ item: RollingProxyOverride, value: Double) -> Double
    }

    final class RoundingRollingProxyOverrideAdjuster: RollingProxyOverrideFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingProxyOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameRollingProxyOverrideAdjuster: RollingProxyOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingProxyOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingProxyOverrideAdjuster: RollingProxyOverrideFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingProxyOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingProxyOverrideAdjuster: RollingProxyOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingProxyOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRollingProxyOverrideAdjuster: RollingProxyOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingProxyOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingProxyOverrideAdjuster: RollingProxyOverrideFactor {
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

        func adjust(_ item: RollingProxyOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling proxy override steps in order and keeps a trace of each.
    final class RollingProxyOverrideEngine {
        var steps: [any RollingProxyOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingProxyOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingProxyOverride) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingProxyOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [RollingProxyOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingProxyOverrideEngine(_ flags: Kit.Flags.Registry) -> RollingProxyOverrideEngine {
        return RollingProxyOverrideEngine(
            steps: [
                RoundingRollingProxyOverrideAdjuster(step: 0.05),
                NameRollingProxyOverrideAdjuster(factors: ["north": 1.37]),
                TieredRollingProxyOverrideAdjuster(bounds: [3968.0, 4356.0, 9832.0], rates: [0.97, 1.2, 1.11]),
                CapRollingProxyOverrideAdjuster(cap: 35650.0),
                MinimumRollingProxyOverrideAdjuster(minimum: 12.5),
                FlaggedRollingProxyOverrideAdjuster(
                    flags: flags,
                    flag: "rolling-proxy-override-global",
                    percent: -5.7
                ),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 79337.5
        )
    }
}
