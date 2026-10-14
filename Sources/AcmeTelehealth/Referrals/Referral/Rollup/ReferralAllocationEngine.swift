import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral allocation calculation.
    protocol ReferralAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: ReferralAllocation, value: Double) -> Double
    }

    final class ReferralAllocationMarginOffsetAdjuster: ReferralAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: ReferralAllocation, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class FlaggedReferralAllocationAdjuster: ReferralAllocationAdjuster {
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

        func adjust(_ item: ReferralAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentReferralAllocationAdjuster: ReferralAllocationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceReferralAllocationAdjuster: ReferralAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ReferralAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingReferralAllocationAdjuster: ReferralAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the referral allocation steps in order and keeps a trace of each.
    final class ReferralAllocationEngine {
        var steps: [any ReferralAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferralAllocation) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [ReferralAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferralAllocationEngine(_ flags: Kit.Flags.Registry) -> ReferralAllocationEngine {
        return ReferralAllocationEngine(
            steps: [
                ReferralAllocationMarginOffsetAdjuster(weight: 0.43),
                FlaggedReferralAllocationAdjuster(flags: flags, flag: "referral-allocation-adaptive", percent: 9.1),
                PercentReferralAllocationAdjuster(percent: -9.6),
                SourceReferralAllocationAdjuster(factors: ["online": 1.28]),
                RoundingReferralAllocationAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 13108.1
        )
    }
}
