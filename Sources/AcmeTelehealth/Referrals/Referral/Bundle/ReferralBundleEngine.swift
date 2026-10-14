import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral bundle calculation.
    protocol ReferralBundleModifier {
        func describe() -> String
        func adjust(_ item: ReferralBundle, value: Double) -> Double
    }

    final class ReferralBundleRevisionOffsetAdjuster: ReferralBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: ReferralBundle, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class RoundingReferralBundleAdjuster: ReferralBundleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentReferralBundleAdjuster: ReferralBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedReferralBundleAdjuster: ReferralBundleModifier {
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

        func adjust(_ item: ReferralBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReferralBundleAdjuster: ReferralBundleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the referral bundle steps in order and keeps a trace of each.
    final class ReferralBundleEngine {
        var steps: [any ReferralBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferralBundle) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralBundleModifier = steps[index]
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

        func evaluateAll(_ items: [ReferralBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferralBundleEngine(_ flags: Kit.Flags.Registry) -> ReferralBundleEngine {
        return ReferralBundleEngine(
            steps: [
                ReferralBundleRevisionOffsetAdjuster(weight: 1.01),
                RoundingReferralBundleAdjuster(step: 0.5),
                PercentReferralBundleAdjuster(percent: -9.4),
                FlaggedReferralBundleAdjuster(flags: flags, flag: "referral-bundle-default", percent: -3.2),
                MinimumReferralBundleAdjuster(minimum: 8.7),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 68852.8
        )
    }
}
