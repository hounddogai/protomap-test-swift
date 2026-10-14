import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending referral milestone calculation.
    protocol PendingReferralMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: PendingReferralMilestone, value: Double) -> Double
    }

    final class RoundingPendingReferralMilestoneAdjuster: PendingReferralMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingReferralMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPendingReferralMilestoneAdjuster: PendingReferralMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingReferralMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingReferralMilestoneAdjuster: PendingReferralMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingReferralMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending referral milestone steps in order and keeps a trace of each.
    final class PendingReferralMilestoneEngine {
        var steps: [any PendingReferralMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingReferralMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingReferralMilestone) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingReferralMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingReferralMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingReferralMilestoneEngine() -> PendingReferralMilestoneEngine {
        return PendingReferralMilestoneEngine(
            steps: [
                RoundingPendingReferralMilestoneAdjuster(step: 5.0),
                PercentPendingReferralMilestoneAdjuster(percent: -2.7),
                MinimumPendingReferralMilestoneAdjuster(minimum: 46.6),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 16591.0
        )
    }
}
