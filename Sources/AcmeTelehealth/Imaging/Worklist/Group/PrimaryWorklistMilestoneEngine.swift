import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary worklist milestone calculation.
    protocol PrimaryWorklistMilestoneModifier {
        func describe() -> String
        func adjust(_ item: PrimaryWorklistMilestone, value: Double) -> Double
    }

    final class PrimaryWorklistMilestoneDurationMinutesOffsetAdjuster: PrimaryWorklistMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: PrimaryWorklistMilestone, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class CapPrimaryWorklistMilestoneAdjuster: PrimaryWorklistMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryWorklistMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrimaryWorklistMilestoneAdjuster: PrimaryWorklistMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryWorklistMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryWorklistMilestoneAdjuster: PrimaryWorklistMilestoneModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryWorklistMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryWorklistMilestoneAdjuster: PrimaryWorklistMilestoneModifier {
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

        func adjust(_ item: PrimaryWorklistMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary worklist milestone steps in order and keeps a trace of each.
    final class PrimaryWorklistMilestoneEngine {
        var steps: [any PrimaryWorklistMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryWorklistMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryWorklistMilestone) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryWorklistMilestoneModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryWorklistMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryWorklistMilestoneEngine(_ flags: Kit.Flags.Registry) -> PrimaryWorklistMilestoneEngine {
        return PrimaryWorklistMilestoneEngine(
            steps: [
                PrimaryWorklistMilestoneDurationMinutesOffsetAdjuster(weight: 0.97),
                CapPrimaryWorklistMilestoneAdjuster(cap: 41082.0),
                MinimumPrimaryWorklistMilestoneAdjuster(minimum: 25.1),
                PercentPrimaryWorklistMilestoneAdjuster(percent: 15.0),
                FlaggedPrimaryWorklistMilestoneAdjuster(
                    flags: flags,
                    flag: "primary-worklist-milestone-strict",
                    percent: -4.1
                ),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 84321.0
        )
    }
}
