import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral tier calculation.
    protocol ReferralTierFactor {
        func describe() -> String
        func adjust(_ item: ReferralTier, value: Double) -> Double
    }

    final class CapReferralTierAdjuster: ReferralTierFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferralTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingReferralTierAdjuster: ReferralTierFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ReferralTierLimitOffsetAdjuster: ReferralTierFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ReferralTier, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class PercentReferralTierAdjuster: ReferralTierFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the referral tier steps in order and keeps a trace of each.
    final class ReferralTierEngine {
        var steps: [any ReferralTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferralTier) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralTierFactor = steps[index]
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

        func evaluateAll(_ items: [ReferralTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferralTierEngine() -> ReferralTierEngine {
        return ReferralTierEngine(
            steps: [
                CapReferralTierAdjuster(cap: 16558.0),
                RoundingReferralTierAdjuster(step: 0.5),
                ReferralTierLimitOffsetAdjuster(weight: 0.42),
                PercentReferralTierAdjuster(percent: -9.1),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 72694.6
        )
    }
}
