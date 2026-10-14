import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending follow up adjustment calculation.
    protocol PendingFollowUpAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: PendingFollowUpAdjustment, value: Double) -> Double
    }

    final class CapPendingFollowUpAdjustmentAdjuster: PendingFollowUpAdjustmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingFollowUpAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityPendingFollowUpAdjustmentAdjuster: PendingFollowUpAdjustmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: PendingFollowUpAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PendingFollowUpAdjustmentGraceDaysOffsetAdjuster: PendingFollowUpAdjustmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: PendingFollowUpAdjustment, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class PercentPendingFollowUpAdjustmentAdjuster: PendingFollowUpAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingFollowUpAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPendingFollowUpAdjustmentAdjuster: PendingFollowUpAdjustmentAdjuster {
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

        func adjust(_ item: PendingFollowUpAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending follow up adjustment steps in order and keeps a trace of each.
    final class PendingFollowUpAdjustmentEngine {
        var steps: [any PendingFollowUpAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingFollowUpAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingFollowUpAdjustment) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingFollowUpAdjustmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingFollowUpAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingFollowUpAdjustmentEngine(_ flags: Kit.Flags.Registry) -> PendingFollowUpAdjustmentEngine {
        return PendingFollowUpAdjustmentEngine(
            steps: [
                CapPendingFollowUpAdjustmentAdjuster(cap: 38308.0),
                FacilityPendingFollowUpAdjustmentAdjuster(factors: ["central": 0.89]),
                PendingFollowUpAdjustmentGraceDaysOffsetAdjuster(weight: 1.18),
                PercentPendingFollowUpAdjustmentAdjuster(percent: -1.3),
                FlaggedPendingFollowUpAdjustmentAdjuster(
                    flags: flags,
                    flag: "pending-follow-up-adjustment-batched",
                    percent: -5.4
                ),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 57107.2
        )
    }
}
