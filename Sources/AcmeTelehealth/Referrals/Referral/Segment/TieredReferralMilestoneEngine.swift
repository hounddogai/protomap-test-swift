import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered referral milestone calculation.
    protocol TieredReferralMilestoneFactor {
        func describe() -> String
        func adjust(_ item: TieredReferralMilestone, value: Double) -> Double
    }

    final class TieredReferralMilestoneMaximumOffsetAdjuster: TieredReferralMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: TieredReferralMilestone, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class FlaggedTieredReferralMilestoneAdjuster: TieredReferralMilestoneFactor {
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

        func adjust(_ item: TieredReferralMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredReferralMilestoneAdjuster: TieredReferralMilestoneFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredReferralMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleTieredReferralMilestoneAdjuster: TieredReferralMilestoneFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TieredReferralMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTieredReferralMilestoneAdjuster: TieredReferralMilestoneFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredReferralMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered referral milestone steps in order and keeps a trace of each.
    final class TieredReferralMilestoneEngine {
        var steps: [any TieredReferralMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredReferralMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredReferralMilestone) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [TieredReferralMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredReferralMilestoneEngine(_ flags: Kit.Flags.Registry) -> TieredReferralMilestoneEngine {
        return TieredReferralMilestoneEngine(
            steps: [
                TieredReferralMilestoneMaximumOffsetAdjuster(weight: 0.92),
                FlaggedTieredReferralMilestoneAdjuster(
                    flags: flags,
                    flag: "tiered-referral-milestone-tiered",
                    percent: -0.9
                ),
                RoundingTieredReferralMilestoneAdjuster(step: 5.0),
                TitleTieredReferralMilestoneAdjuster(factors: ["west": 1.29]),
                CapTieredReferralMilestoneAdjuster(cap: 46758.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 93129.8
        )
    }
}
