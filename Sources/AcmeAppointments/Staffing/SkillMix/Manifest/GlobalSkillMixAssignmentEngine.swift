import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global skill mix assignment calculation.
    protocol GlobalSkillMixAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalSkillMixAssignment, value: Double) -> Double
    }

    final class RoundingGlobalSkillMixAssignmentAdjuster: GlobalSkillMixAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalSkillMixAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedGlobalSkillMixAssignmentAdjuster: GlobalSkillMixAssignmentAdjuster {
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

        func adjust(_ item: GlobalSkillMixAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalSkillMixAssignmentAdjuster: GlobalSkillMixAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalSkillMixAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global skill mix assignment steps in order and keeps a trace of each.
    final class GlobalSkillMixAssignmentEngine {
        var steps: [any GlobalSkillMixAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSkillMixAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalSkillMixAssignment) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalSkillMixAssignmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalSkillMixAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalSkillMixAssignmentEngine(_ flags: Kit.Flags.Registry) -> GlobalSkillMixAssignmentEngine {
        return GlobalSkillMixAssignmentEngine(
            steps: [
                RoundingGlobalSkillMixAssignmentAdjuster(step: 5.0),
                FlaggedGlobalSkillMixAssignmentAdjuster(
                    flags: flags,
                    flag: "global-skill-mix-assignment-weighted",
                    percent: -2.4
                ),
                CapGlobalSkillMixAssignmentAdjuster(cap: 42210.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 61521.8
        )
    }
}
