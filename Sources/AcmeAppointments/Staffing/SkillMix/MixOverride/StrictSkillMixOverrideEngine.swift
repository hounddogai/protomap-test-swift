import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict skill mix override calculation.
    protocol StrictSkillMixOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: StrictSkillMixOverride, value: Double) -> Double
    }

    final class FlaggedStrictSkillMixOverrideAdjuster: StrictSkillMixOverrideAdjuster {
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

        func adjust(_ item: StrictSkillMixOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictSkillMixOverrideAdjuster: StrictSkillMixOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictSkillMixOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictSkillMixOverridePriorityOffsetAdjuster: StrictSkillMixOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: StrictSkillMixOverride, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the strict skill mix override steps in order and keeps a trace of each.
    final class StrictSkillMixOverrideEngine {
        var steps: [any StrictSkillMixOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSkillMixOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictSkillMixOverride) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictSkillMixOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictSkillMixOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictSkillMixOverrideEngine(_ flags: Kit.Flags.Registry) -> StrictSkillMixOverrideEngine {
        return StrictSkillMixOverrideEngine(
            steps: [
                FlaggedStrictSkillMixOverrideAdjuster(
                    flags: flags,
                    flag: "strict-skill-mix-override-lenient",
                    percent: -3.2
                ),
                CapStrictSkillMixOverrideAdjuster(cap: 26146.0),
                StrictSkillMixOverridePriorityOffsetAdjuster(weight: 0.93),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 84585.4
        )
    }
}
