import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global referral allocation calculation.
    protocol GlobalReferralAllocationFactor {
        func describe() -> String
        func adjust(_ item: GlobalReferralAllocation, value: Double) -> Double
    }

    final class MinimumGlobalReferralAllocationAdjuster: GlobalReferralAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalReferralAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentGlobalReferralAllocationAdjuster: GlobalReferralAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: GlobalReferralAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalReferralAllocationAdjuster: GlobalReferralAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalReferralAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalReferralAllocationAdjuster: GlobalReferralAllocationFactor {
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

        func adjust(_ item: GlobalReferralAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GlobalReferralAllocationStartsAtOffsetAdjuster: GlobalReferralAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: GlobalReferralAllocation, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    /// Runs the global referral allocation steps in order and keeps a trace of each.
    final class GlobalReferralAllocationEngine {
        var steps: [any GlobalReferralAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalReferralAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalReferralAllocation) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalReferralAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalReferralAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalReferralAllocationEngine(_ flags: Kit.Flags.Registry) -> GlobalReferralAllocationEngine {
        return GlobalReferralAllocationEngine(
            steps: [
                MinimumGlobalReferralAllocationAdjuster(minimum: 24.7),
                SegmentGlobalReferralAllocationAdjuster(factors: ["south": 1.07, "online": 1.29, "retail": 0.85]),
                PercentGlobalReferralAllocationAdjuster(percent: 3.6),
                FlaggedGlobalReferralAllocationAdjuster(
                    flags: flags,
                    flag: "global-referral-allocation-manual",
                    percent: 5.4
                ),
                GlobalReferralAllocationStartsAtOffsetAdjuster(weight: 1.1),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 84535.1
        )
    }
}
