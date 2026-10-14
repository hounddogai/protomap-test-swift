import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive eligibility milestone calculation.
    protocol AdaptiveEligibilityMilestoneFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveEligibilityMilestone, value: Double) -> Double
    }

    final class MinimumAdaptiveEligibilityMilestoneAdjuster: AdaptiveEligibilityMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveEligibilityMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAdaptiveEligibilityMilestoneAdjuster: AdaptiveEligibilityMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveEligibilityMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveEligibilityMilestoneAdjuster: AdaptiveEligibilityMilestoneFactor {
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

        func adjust(_ item: AdaptiveEligibilityMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive eligibility milestone steps in order and keeps a trace of each.
    final class AdaptiveEligibilityMilestoneEngine {
        var steps: [any AdaptiveEligibilityMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveEligibilityMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveEligibilityMilestone) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveEligibilityMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveEligibilityMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveEligibilityMilestoneEngine(_ flags: Kit.Flags.Registry) -> AdaptiveEligibilityMilestoneEngine {
        return AdaptiveEligibilityMilestoneEngine(
            steps: [
                MinimumAdaptiveEligibilityMilestoneAdjuster(minimum: 34.3),
                PercentAdaptiveEligibilityMilestoneAdjuster(percent: -3.9),
                FlaggedAdaptiveEligibilityMilestoneAdjuster(
                    flags: flags,
                    flag: "adaptive-eligibility-milestone-tiered",
                    percent: 6.8
                ),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 45939.6
        )
    }
}
