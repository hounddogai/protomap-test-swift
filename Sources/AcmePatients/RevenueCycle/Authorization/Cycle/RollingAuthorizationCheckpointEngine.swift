import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling authorization checkpoint calculation.
    protocol RollingAuthorizationCheckpointFactor {
        func describe() -> String
        func adjust(_ item: RollingAuthorizationCheckpoint, value: Double) -> Double
    }

    final class RoundingRollingAuthorizationCheckpointAdjuster: RollingAuthorizationCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingAuthorizationCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRollingAuthorizationCheckpointAdjuster: RollingAuthorizationCheckpointFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingAuthorizationCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingAuthorizationCheckpointAdjuster: RollingAuthorizationCheckpointFactor {
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

        func adjust(_ item: RollingAuthorizationCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryRollingAuthorizationCheckpointAdjuster: RollingAuthorizationCheckpointFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RollingAuthorizationCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRollingAuthorizationCheckpointAdjuster: RollingAuthorizationCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingAuthorizationCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRollingAuthorizationCheckpointAdjuster: RollingAuthorizationCheckpointFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingAuthorizationCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling authorization checkpoint steps in order and keeps a trace of each.
    final class RollingAuthorizationCheckpointEngine {
        var steps: [any RollingAuthorizationCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAuthorizationCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingAuthorizationCheckpoint) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [RollingAuthorizationCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingAuthorizationCheckpointEngine(_ flags: Kit.Flags.Registry) -> RollingAuthorizationCheckpointEngine {
        return RollingAuthorizationCheckpointEngine(
            steps: [
                RoundingRollingAuthorizationCheckpointAdjuster(step: 0.05),
                TieredRollingAuthorizationCheckpointAdjuster(bounds: [3052.0, 9205.0], rates: [0.96, 1.1]),
                FlaggedRollingAuthorizationCheckpointAdjuster(
                    flags: flags,
                    flag: "rolling-authorization-checkpoint-fallback",
                    percent: -0.7
                ),
                CategoryRollingAuthorizationCheckpointAdjuster(factors: ["east": 1.28, "west": 1.06, "online": 1.0]),
                CapRollingAuthorizationCheckpointAdjuster(cap: 45188.0),
                PercentRollingAuthorizationCheckpointAdjuster(percent: -6.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 55616.5
        )
    }
}
