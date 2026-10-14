import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rolling rounding digest calculation.
    protocol RollingRoundingDigestStep {
        func describe() -> String
        func adjust(_ item: RollingRoundingDigest, value: Double) -> Double
    }

    final class RollingRoundingDigestExpiresAtOffsetAdjuster: RollingRoundingDigestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: RollingRoundingDigest, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingRollingRoundingDigestAdjuster: RollingRoundingDigestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingRoundingDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRollingRoundingDigestAdjuster: RollingRoundingDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingRoundingDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingRoundingDigestAdjuster: RollingRoundingDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingRoundingDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingRoundingDigestAdjuster: RollingRoundingDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingRoundingDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRollingRoundingDigestAdjuster: RollingRoundingDigestStep {
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

        func adjust(_ item: RollingRoundingDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling rounding digest steps in order and keeps a trace of each.
    final class RollingRoundingDigestEngine {
        var steps: [any RollingRoundingDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingRoundingDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingRoundingDigest) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingRoundingDigestStep = steps[index]
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

        func evaluateAll(_ items: [RollingRoundingDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingRoundingDigestEngine(_ flags: Kit.Flags.Registry) -> RollingRoundingDigestEngine {
        return RollingRoundingDigestEngine(
            steps: [
                RollingRoundingDigestExpiresAtOffsetAdjuster(weight: 0.25),
                RoundingRollingRoundingDigestAdjuster(step: 1.0),
                MinimumRollingRoundingDigestAdjuster(minimum: 24.3),
                TieredRollingRoundingDigestAdjuster(
                    bounds: [3122.0, 4044.0, 5629.0, 9669.0],
                    rates: [0.84, 0.95, 1.12, 1.04]
                ),
                CapRollingRoundingDigestAdjuster(cap: 48293.0),
                FlaggedRollingRoundingDigestAdjuster(
                    flags: flags,
                    flag: "rolling-rounding-digest-default",
                    percent: -9.1
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 66144.6
        )
    }
}
