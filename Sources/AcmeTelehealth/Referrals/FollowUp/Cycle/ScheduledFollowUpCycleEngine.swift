import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled follow up cycle calculation.
    protocol ScheduledFollowUpCycleStep {
        func describe() -> String
        func adjust(_ item: ScheduledFollowUpCycle, value: Double) -> Double
    }

    final class PercentScheduledFollowUpCycleAdjuster: ScheduledFollowUpCycleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledFollowUpCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledFollowUpCycleAdjuster: ScheduledFollowUpCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledFollowUpCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledFollowUpCycleVisitMinutesOffsetAdjuster: ScheduledFollowUpCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: ScheduledFollowUpCycle, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class FlaggedScheduledFollowUpCycleAdjuster: ScheduledFollowUpCycleStep {
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

        func adjust(_ item: ScheduledFollowUpCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledFollowUpCycleAdjuster: ScheduledFollowUpCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledFollowUpCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled follow up cycle steps in order and keeps a trace of each.
    final class ScheduledFollowUpCycleEngine {
        var steps: [any ScheduledFollowUpCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledFollowUpCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledFollowUpCycle) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ScheduledFollowUpCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledFollowUpCycleEngine(_ flags: Kit.Flags.Registry) -> ScheduledFollowUpCycleEngine {
        return ScheduledFollowUpCycleEngine(
            steps: [
                PercentScheduledFollowUpCycleAdjuster(percent: -9.7),
                TieredScheduledFollowUpCycleAdjuster(
                    bounds: [6403.0, 7235.0, 7373.0, 8264.0],
                    rates: [0.95, 1.07, 0.84, 1.09]
                ),
                ScheduledFollowUpCycleVisitMinutesOffsetAdjuster(weight: 0.24),
                FlaggedScheduledFollowUpCycleAdjuster(
                    flags: flags,
                    flag: "scheduled-follow-up-cycle-pending",
                    percent: -1.0
                ),
                CapScheduledFollowUpCycleAdjuster(cap: 16571.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 10796.5
        )
    }
}
