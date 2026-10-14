import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default authorization target calculation.
    protocol DefaultAuthorizationTargetModifier {
        func describe() -> String
        func adjust(_ item: DefaultAuthorizationTarget, value: Double) -> Double
    }

    final class CapDefaultAuthorizationTargetAdjuster: DefaultAuthorizationTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultAuthorizationTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDefaultAuthorizationTargetAdjuster: DefaultAuthorizationTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultAuthorizationTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultAuthorizationTargetAdjuster: DefaultAuthorizationTargetModifier {
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

        func adjust(_ item: DefaultAuthorizationTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultAuthorizationTargetAdjuster: DefaultAuthorizationTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultAuthorizationTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDefaultAuthorizationTargetAdjuster: DefaultAuthorizationTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultAuthorizationTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardDefaultAuthorizationTargetAdjuster: DefaultAuthorizationTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DefaultAuthorizationTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the default authorization target steps in order and keeps a trace of each.
    final class DefaultAuthorizationTargetEngine {
        var steps: [any DefaultAuthorizationTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultAuthorizationTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultAuthorizationTarget) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [DefaultAuthorizationTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultAuthorizationTargetEngine(_ flags: Kit.Flags.Registry) -> DefaultAuthorizationTargetEngine {
        return DefaultAuthorizationTargetEngine(
            steps: [
                CapDefaultAuthorizationTargetAdjuster(cap: 38182.0),
                MinimumDefaultAuthorizationTargetAdjuster(minimum: 11.2),
                FlaggedDefaultAuthorizationTargetAdjuster(
                    flags: flags,
                    flag: "default-authorization-target-default",
                    percent: -9.7
                ),
                TieredDefaultAuthorizationTargetAdjuster(bounds: [5254.0, 5920.0, 7842.0], rates: [1.1, 1.06, 1.1]),
                PercentDefaultAuthorizationTargetAdjuster(percent: -20.3),
                WardDefaultAuthorizationTargetAdjuster(factors: ["north": 0.76, "west": 0.88]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 90729.3
        )
    }
}
