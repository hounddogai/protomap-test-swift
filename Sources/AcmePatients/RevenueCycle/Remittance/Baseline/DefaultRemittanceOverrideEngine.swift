import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default remittance override calculation.
    protocol DefaultRemittanceOverrideModifier {
        func describe() -> String
        func adjust(_ item: DefaultRemittanceOverride, value: Double) -> Double
    }

    final class PercentDefaultRemittanceOverrideAdjuster: DefaultRemittanceOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRemittanceOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceDefaultRemittanceOverrideAdjuster: DefaultRemittanceOverrideModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: DefaultRemittanceOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDefaultRemittanceOverrideAdjuster: DefaultRemittanceOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRemittanceOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultRemittanceOverrideAdjuster: DefaultRemittanceOverrideModifier {
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

        func adjust(_ item: DefaultRemittanceOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultRemittanceOverrideAdjuster: DefaultRemittanceOverrideModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRemittanceOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDefaultRemittanceOverrideAdjuster: DefaultRemittanceOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultRemittanceOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default remittance override steps in order and keeps a trace of each.
    final class DefaultRemittanceOverrideEngine {
        var steps: [any DefaultRemittanceOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRemittanceOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRemittanceOverride) -> Double {
            var current = item.netVolume()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [DefaultRemittanceOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRemittanceOverrideEngine(_ flags: Kit.Flags.Registry) -> DefaultRemittanceOverrideEngine {
        return DefaultRemittanceOverrideEngine(
            steps: [
                PercentDefaultRemittanceOverrideAdjuster(percent: 0.3),
                SourceDefaultRemittanceOverrideAdjuster(factors: ["retail": 1.02]),
                MinimumDefaultRemittanceOverrideAdjuster(minimum: 41.3),
                FlaggedDefaultRemittanceOverrideAdjuster(
                    flags: flags,
                    flag: "default-remittance-override-strict",
                    percent: 3.5
                ),
                RoundingDefaultRemittanceOverrideAdjuster(step: 0.5),
                CapDefaultRemittanceOverrideAdjuster(cap: 5571.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 37845.8
        )
    }
}
