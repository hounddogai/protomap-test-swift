import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary referral milestone calculation.
    protocol PrimaryReferralMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryReferralMilestone, value: Double) -> Double
    }

    final class FlaggedPrimaryReferralMilestoneAdjuster: PrimaryReferralMilestoneAdjuster {
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

        func adjust(_ item: PrimaryReferralMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryReferralMilestoneAdjuster: PrimaryReferralMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryReferralMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPrimaryReferralMilestoneAdjuster: PrimaryReferralMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryReferralMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryReferralMilestoneAdjuster: PrimaryReferralMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryReferralMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPrimaryReferralMilestoneAdjuster: PrimaryReferralMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryReferralMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryReferralMilestoneCapacityOffsetAdjuster: PrimaryReferralMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: PrimaryReferralMilestone, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the primary referral milestone steps in order and keeps a trace of each.
    final class PrimaryReferralMilestoneEngine {
        var steps: [any PrimaryReferralMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryReferralMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryReferralMilestone) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryReferralMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryReferralMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryReferralMilestoneEngine(_ flags: Kit.Flags.Registry) -> PrimaryReferralMilestoneEngine {
        return PrimaryReferralMilestoneEngine(
            steps: [
                FlaggedPrimaryReferralMilestoneAdjuster(
                    flags: flags,
                    flag: "primary-referral-milestone-legacy",
                    percent: -7.9
                ),
                CapPrimaryReferralMilestoneAdjuster(cap: 29486.0),
                TieredPrimaryReferralMilestoneAdjuster(bounds: [710.0, 7282.0, 8986.0], rates: [0.93, 0.82, 0.94]),
                RoundingPrimaryReferralMilestoneAdjuster(step: 1.0),
                PercentPrimaryReferralMilestoneAdjuster(percent: 19.9),
                PrimaryReferralMilestoneCapacityOffsetAdjuster(weight: 1.9),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 17940.5
        )
    }
}
