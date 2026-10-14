import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled claim milestone calculation.
    protocol ScheduledClaimMilestoneFactor {
        func describe() -> String
        func adjust(_ item: ScheduledClaimMilestone, value: Double) -> Double
    }

    final class MinimumScheduledClaimMilestoneAdjuster: ScheduledClaimMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledClaimMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledClaimMilestoneAdjuster: ScheduledClaimMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledClaimMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedScheduledClaimMilestoneAdjuster: ScheduledClaimMilestoneFactor {
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

        func adjust(_ item: ScheduledClaimMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledClaimMilestoneDurationMinutesOffsetAdjuster: ScheduledClaimMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: ScheduledClaimMilestone, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class CapScheduledClaimMilestoneAdjuster: ScheduledClaimMilestoneFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledClaimMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredScheduledClaimMilestoneAdjuster: ScheduledClaimMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledClaimMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled claim milestone steps in order and keeps a trace of each.
    final class ScheduledClaimMilestoneEngine {
        var steps: [any ScheduledClaimMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledClaimMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledClaimMilestone) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [ScheduledClaimMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledClaimMilestoneEngine(_ flags: Kit.Flags.Registry) -> ScheduledClaimMilestoneEngine {
        return ScheduledClaimMilestoneEngine(
            steps: [
                MinimumScheduledClaimMilestoneAdjuster(minimum: 49.4),
                PercentScheduledClaimMilestoneAdjuster(percent: 18.4),
                FlaggedScheduledClaimMilestoneAdjuster(
                    flags: flags,
                    flag: "scheduled-claim-milestone-fallback",
                    percent: 8.2
                ),
                ScheduledClaimMilestoneDurationMinutesOffsetAdjuster(weight: 0.93),
                CapScheduledClaimMilestoneAdjuster(cap: 37190.0),
                TieredScheduledClaimMilestoneAdjuster(
                    bounds: [2944.0, 4349.0, 5661.0, 9912.0],
                    rates: [1.1, 0.82, 1.09, 1.11]
                ),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 4961.7
        )
    }
}
