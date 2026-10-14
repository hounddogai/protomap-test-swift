import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global referral cycle calculation.
    protocol GlobalReferralCycleStep {
        func describe() -> String
        func adjust(_ item: GlobalReferralCycle, value: Double) -> Double
    }

    final class MinimumGlobalReferralCycleAdjuster: GlobalReferralCycleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalReferralCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class GlobalReferralCycleDurationMinutesOffsetAdjuster: GlobalReferralCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: GlobalReferralCycle, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class FlaggedGlobalReferralCycleAdjuster: GlobalReferralCycleStep {
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

        func adjust(_ item: GlobalReferralCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalReferralCycleAdjuster: GlobalReferralCycleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalReferralCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapGlobalReferralCycleAdjuster: GlobalReferralCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalReferralCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global referral cycle steps in order and keeps a trace of each.
    final class GlobalReferralCycleEngine {
        var steps: [any GlobalReferralCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalReferralCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalReferralCycle) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalReferralCycleStep = steps[index]
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

        func evaluateAll(_ items: [GlobalReferralCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalReferralCycleEngine(_ flags: Kit.Flags.Registry) -> GlobalReferralCycleEngine {
        return GlobalReferralCycleEngine(
            steps: [
                MinimumGlobalReferralCycleAdjuster(minimum: 25.2),
                GlobalReferralCycleDurationMinutesOffsetAdjuster(weight: 0.7),
                FlaggedGlobalReferralCycleAdjuster(flags: flags, flag: "global-referral-cycle-legacy", percent: -1.8),
                RoundingGlobalReferralCycleAdjuster(step: 0.05),
                CapGlobalReferralCycleAdjuster(cap: 40333.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 33854.2
        )
    }
}
