import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled authorization digest calculation.
    protocol ScheduledAuthorizationDigestStep {
        func describe() -> String
        func adjust(_ item: ScheduledAuthorizationDigest, value: Double) -> Double
    }

    final class PercentScheduledAuthorizationDigestAdjuster: ScheduledAuthorizationDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledAuthorizationDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledAuthorizationDigestAdjuster: ScheduledAuthorizationDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAuthorizationDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledAuthorizationDigestAdjuster: ScheduledAuthorizationDigestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledAuthorizationDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedScheduledAuthorizationDigestAdjuster: ScheduledAuthorizationDigestStep {
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

        func adjust(_ item: ScheduledAuthorizationDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledAuthorizationDigestAdjuster: ScheduledAuthorizationDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledAuthorizationDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled authorization digest steps in order and keeps a trace of each.
    final class ScheduledAuthorizationDigestEngine {
        var steps: [any ScheduledAuthorizationDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAuthorizationDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledAuthorizationDigest) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [ScheduledAuthorizationDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledAuthorizationDigestEngine(_ flags: Kit.Flags.Registry) -> ScheduledAuthorizationDigestEngine {
        return ScheduledAuthorizationDigestEngine(
            steps: [
                PercentScheduledAuthorizationDigestAdjuster(percent: 22.9),
                MinimumScheduledAuthorizationDigestAdjuster(minimum: 7.2),
                RoundingScheduledAuthorizationDigestAdjuster(step: 0.1),
                FlaggedScheduledAuthorizationDigestAdjuster(
                    flags: flags,
                    flag: "scheduled-authorization-digest-default",
                    percent: 2.9
                ),
                TieredScheduledAuthorizationDigestAdjuster(bounds: [608.0, 2868.0], rates: [0.8, 1.18]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 35368.5
        )
    }
}
