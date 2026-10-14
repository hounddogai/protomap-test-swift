import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary skill mix score calculation.
    protocol PrimarySkillMixScoreFactor {
        func describe() -> String
        func adjust(_ item: PrimarySkillMixScore, value: Double) -> Double
    }

    final class MinimumPrimarySkillMixScoreAdjuster: PrimarySkillMixScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimarySkillMixScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPrimarySkillMixScoreAdjuster: PrimarySkillMixScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimarySkillMixScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPrimarySkillMixScoreAdjuster: PrimarySkillMixScoreFactor {
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

        func adjust(_ item: PrimarySkillMixScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary skill mix score steps in order and keeps a trace of each.
    final class PrimarySkillMixScoreEngine {
        var steps: [any PrimarySkillMixScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySkillMixScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimarySkillMixScore) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimarySkillMixScoreFactor = steps[index]
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

        func evaluateAll(_ items: [PrimarySkillMixScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimarySkillMixScoreEngine(_ flags: Kit.Flags.Registry) -> PrimarySkillMixScoreEngine {
        return PrimarySkillMixScoreEngine(
            steps: [
                MinimumPrimarySkillMixScoreAdjuster(minimum: 35.7),
                RoundingPrimarySkillMixScoreAdjuster(step: 5.0),
                FlaggedPrimarySkillMixScoreAdjuster(
                    flags: flags,
                    flag: "primary-skill-mix-score-tiered",
                    percent: -8.9
                ),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 24888.1
        )
    }
}
