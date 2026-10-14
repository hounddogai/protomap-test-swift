import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled census plan calculation.
    protocol ScheduledCensusPlanFactor {
        func describe() -> String
        func adjust(_ item: ScheduledCensusPlan, value: Double) -> Double
    }

    final class PercentScheduledCensusPlanAdjuster: ScheduledCensusPlanFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCensusPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledCensusPlanAdjuster: ScheduledCensusPlanFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCensusPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledCensusPlanAdjuster: ScheduledCensusPlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCensusPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedScheduledCensusPlanAdjuster: ScheduledCensusPlanFactor {
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

        func adjust(_ item: ScheduledCensusPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled census plan steps in order and keeps a trace of each.
    final class ScheduledCensusPlanEngine {
        var steps: [any ScheduledCensusPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCensusPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledCensusPlan) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledCensusPlanFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledCensusPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledCensusPlanEngine(_ flags: Kit.Flags.Registry) -> ScheduledCensusPlanEngine {
        return ScheduledCensusPlanEngine(
            steps: [
                PercentScheduledCensusPlanAdjuster(percent: -24.4),
                MinimumScheduledCensusPlanAdjuster(minimum: 2.6),
                CapScheduledCensusPlanAdjuster(cap: 31874.0),
                FlaggedScheduledCensusPlanAdjuster(flags: flags, flag: "scheduled-census-plan-primary", percent: 0.3),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 65019.2
        )
    }
}
