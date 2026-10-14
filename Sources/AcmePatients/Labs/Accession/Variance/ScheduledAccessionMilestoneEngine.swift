import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled accession milestone calculation.
    protocol ScheduledAccessionMilestoneModifier {
        func describe() -> String
        func adjust(_ item: ScheduledAccessionMilestone, value: Double) -> Double
    }

    final class FlaggedScheduledAccessionMilestoneAdjuster: ScheduledAccessionMilestoneModifier {
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

        func adjust(_ item: ScheduledAccessionMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledAccessionMilestoneAdjuster: ScheduledAccessionMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAccessionMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledAccessionMilestoneAdjuster: ScheduledAccessionMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledAccessionMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WardScheduledAccessionMilestoneAdjuster: ScheduledAccessionMilestoneModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ScheduledAccessionMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled accession milestone steps in order and keeps a trace of each.
    final class ScheduledAccessionMilestoneEngine {
        var steps: [any ScheduledAccessionMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAccessionMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledAccessionMilestone) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ScheduledAccessionMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledAccessionMilestoneEngine(_ flags: Kit.Flags.Registry) -> ScheduledAccessionMilestoneEngine {
        return ScheduledAccessionMilestoneEngine(
            steps: [
                FlaggedScheduledAccessionMilestoneAdjuster(
                    flags: flags,
                    flag: "scheduled-accession-milestone-seasonal",
                    percent: 5.2
                ),
                MinimumScheduledAccessionMilestoneAdjuster(minimum: 21.8),
                CapScheduledAccessionMilestoneAdjuster(cap: 18631.0),
                WardScheduledAccessionMilestoneAdjuster(factors: ["south": 0.85, "retail": 1.32, "east": 1.28]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 80955.1
        )
    }
}
