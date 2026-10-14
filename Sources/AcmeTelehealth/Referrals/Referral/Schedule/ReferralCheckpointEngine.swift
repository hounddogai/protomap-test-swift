import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral checkpoint calculation.
    protocol ReferralCheckpointFactor {
        func describe() -> String
        func adjust(_ item: ReferralCheckpoint, value: Double) -> Double
    }

    final class PercentReferralCheckpointAdjuster: ReferralCheckpointFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedReferralCheckpointAdjuster: ReferralCheckpointFactor {
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

        func adjust(_ item: ReferralCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapReferralCheckpointAdjuster: ReferralCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferralCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumReferralCheckpointAdjuster: ReferralCheckpointFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingReferralCheckpointAdjuster: ReferralCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ReferralCheckpointRatioOffsetAdjuster: ReferralCheckpointFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ReferralCheckpoint, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the referral checkpoint steps in order and keeps a trace of each.
    final class ReferralCheckpointEngine {
        var steps: [any ReferralCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReferralCheckpoint) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ReferralCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReferralCheckpointEngine(_ flags: Kit.Flags.Registry) -> ReferralCheckpointEngine {
        return ReferralCheckpointEngine(
            steps: [
                PercentReferralCheckpointAdjuster(percent: 22.5),
                FlaggedReferralCheckpointAdjuster(flags: flags, flag: "referral-checkpoint-lenient", percent: 2.9),
                CapReferralCheckpointAdjuster(cap: 30977.0),
                MinimumReferralCheckpointAdjuster(minimum: 39.1),
                RoundingReferralCheckpointAdjuster(step: 0.25),
                ReferralCheckpointRatioOffsetAdjuster(weight: 0.11),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 20595.6
        )
    }
}
