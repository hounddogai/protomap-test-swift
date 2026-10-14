import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral snapshot calculation.
    protocol ReferralSnapshotFactor {
        func describe() -> String
        func adjust(_ item: ReferralSnapshot, value: Double) -> Double
    }

    final class PercentReferralSnapshotAdjuster: ReferralSnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReferralSnapshotAdjuster: ReferralSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredReferralSnapshotAdjuster: ReferralSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingReferralSnapshotAdjuster: ReferralSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionReferralSnapshotAdjuster: ReferralSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ReferralSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedReferralSnapshotAdjuster: ReferralSnapshotFactor {
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

        func adjust(_ item: ReferralSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the referral snapshot steps in order and keeps a trace of each.
    final class ReferralSnapshotEngine {
        var steps: [any ReferralSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferralSnapshot) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralSnapshotFactor = steps[index]
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

        func evaluateAll(_ items: [ReferralSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferralSnapshotEngine(_ flags: Kit.Flags.Registry) -> ReferralSnapshotEngine {
        return ReferralSnapshotEngine(
            steps: [
                PercentReferralSnapshotAdjuster(percent: -17.5),
                MinimumReferralSnapshotAdjuster(minimum: 35.5),
                TieredReferralSnapshotAdjuster(
                    bounds: [603.0, 963.0, 2844.0, 6326.0],
                    rates: [0.92, 1.15, 1.04, 0.97]
                ),
                RoundingReferralSnapshotAdjuster(step: 5.0),
                RegionReferralSnapshotAdjuster(factors: ["east": 1.29]),
                FlaggedReferralSnapshotAdjuster(flags: flags, flag: "referral-snapshot-lenient", percent: 0.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 30672.6
        )
    }
}
