import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary referral exception calculation.
    protocol PrimaryReferralExceptionModifier {
        func describe() -> String
        func adjust(_ item: PrimaryReferralException, value: Double) -> Double
    }

    final class FlaggedPrimaryReferralExceptionAdjuster: PrimaryReferralExceptionModifier {
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

        func adjust(_ item: PrimaryReferralException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPrimaryReferralExceptionAdjuster: PrimaryReferralExceptionModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryReferralException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryReferralExceptionBatchSizeOffsetAdjuster: PrimaryReferralExceptionModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: PrimaryReferralException, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class CategoryPrimaryReferralExceptionAdjuster: PrimaryReferralExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PrimaryReferralException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPrimaryReferralExceptionAdjuster: PrimaryReferralExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryReferralException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary referral exception steps in order and keeps a trace of each.
    final class PrimaryReferralExceptionEngine {
        var steps: [any PrimaryReferralExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryReferralExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryReferralException) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryReferralExceptionModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryReferralException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryReferralExceptionEngine(_ flags: Kit.Flags.Registry) -> PrimaryReferralExceptionEngine {
        return PrimaryReferralExceptionEngine(
            steps: [
                FlaggedPrimaryReferralExceptionAdjuster(
                    flags: flags,
                    flag: "primary-referral-exception-regional",
                    percent: 0.5
                ),
                PercentPrimaryReferralExceptionAdjuster(percent: -6.9),
                PrimaryReferralExceptionBatchSizeOffsetAdjuster(weight: 0.15),
                CategoryPrimaryReferralExceptionAdjuster(factors: ["north": 0.96, "central": 1.34, "east": 1.39]),
                MinimumPrimaryReferralExceptionAdjuster(minimum: 24.4),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 35141.6
        )
    }
}
