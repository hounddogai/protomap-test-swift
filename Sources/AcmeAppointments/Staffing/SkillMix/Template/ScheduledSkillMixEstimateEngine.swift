import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the scheduled skill mix estimate calculation.
    protocol ScheduledSkillMixEstimateStep {
        func describe() -> String
        func adjust(_ item: ScheduledSkillMixEstimate, value: Double) -> Double
    }

    final class ScheduledSkillMixEstimateSequenceOffsetAdjuster: ScheduledSkillMixEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: ScheduledSkillMixEstimate, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class FlaggedScheduledSkillMixEstimateAdjuster: ScheduledSkillMixEstimateStep {
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

        func adjust(_ item: ScheduledSkillMixEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledSkillMixEstimateAdjuster: ScheduledSkillMixEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledSkillMixEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled skill mix estimate steps in order and keeps a trace of each.
    final class ScheduledSkillMixEstimateEngine {
        var steps: [any ScheduledSkillMixEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledSkillMixEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledSkillMixEstimate) -> Double {
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

        func evaluateAll(_ items: [ScheduledSkillMixEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledSkillMixEstimateEngine(_ flags: Kit.Flags.Registry) -> ScheduledSkillMixEstimateEngine {
        return ScheduledSkillMixEstimateEngine(
            steps: [
                ScheduledSkillMixEstimateSequenceOffsetAdjuster(weight: 1.66),
                FlaggedScheduledSkillMixEstimateAdjuster(
                    flags: flags,
                    flag: "scheduled-skill-mix-estimate-tiered",
                    percent: 2.3
                ),
                PercentScheduledSkillMixEstimateAdjuster(percent: 2.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 13882.0
        )
    }
}
