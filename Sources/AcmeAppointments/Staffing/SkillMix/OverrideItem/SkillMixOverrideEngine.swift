import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix override calculation.
    protocol SkillMixOverrideFactor {
        func describe() -> String
        func adjust(_ item: SkillMixOverride, value: Double) -> Double
    }

    final class RoundingSkillMixOverrideAdjuster: SkillMixOverrideFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSkillMixOverrideAdjuster: SkillMixOverrideFactor {
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

        func adjust(_ item: SkillMixOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSkillMixOverrideAdjuster: SkillMixOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the skill mix override steps in order and keeps a trace of each.
    final class SkillMixOverrideEngine {
        var steps: [any SkillMixOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SkillMixOverride) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [SkillMixOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSkillMixOverrideEngine(_ flags: Kit.Flags.Registry) -> SkillMixOverrideEngine {
        return SkillMixOverrideEngine(
            steps: [
                RoundingSkillMixOverrideAdjuster(step: 0.5),
                FlaggedSkillMixOverrideAdjuster(flags: flags, flag: "skill-mix-override-rolling", percent: -8.6),
                MinimumSkillMixOverrideAdjuster(minimum: 38.8),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 42718.8
        )
    }
}
