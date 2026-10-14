import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral group calculation.
    protocol ReferralGroupAdjuster {
        func describe() -> String
        func adjust(_ item: ReferralGroup, value: Double) -> Double
    }

    final class MinimumReferralGroupAdjuster: ReferralGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredReferralGroupAdjuster: ReferralGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ReferralGroupPriorityOffsetAdjuster: ReferralGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: ReferralGroup, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class FlaggedReferralGroupAdjuster: ReferralGroupAdjuster {
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

        func adjust(_ item: ReferralGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the referral group steps in order and keeps a trace of each.
    final class ReferralGroupEngine {
        var steps: [any ReferralGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferralGroup) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [ReferralGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferralGroupEngine(_ flags: Kit.Flags.Registry) -> ReferralGroupEngine {
        return ReferralGroupEngine(
            steps: [
                MinimumReferralGroupAdjuster(minimum: 0.7),
                TieredReferralGroupAdjuster(bounds: [470.0, 9232.0], rates: [0.9, 1.2]),
                ReferralGroupPriorityOffsetAdjuster(weight: 1.22),
                FlaggedReferralGroupAdjuster(flags: flags, flag: "referral-group-lenient", percent: -0.5),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 26448.1
        )
    }
}
