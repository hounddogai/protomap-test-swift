import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy skill mix milestone calculation.
    protocol LegacySkillMixMilestoneModifier {
        func describe() -> String
        func adjust(_ item: LegacySkillMixMilestone, value: Double) -> Double
    }

    final class PercentLegacySkillMixMilestoneAdjuster: LegacySkillMixMilestoneModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacySkillMixMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacySkillMixMilestoneAdjuster: LegacySkillMixMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacySkillMixMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLegacySkillMixMilestoneAdjuster: LegacySkillMixMilestoneModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacySkillMixMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleLegacySkillMixMilestoneAdjuster: LegacySkillMixMilestoneModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: LegacySkillMixMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy skill mix milestone steps in order and keeps a trace of each.
    final class LegacySkillMixMilestoneEngine {
        var steps: [any LegacySkillMixMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacySkillMixMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacySkillMixMilestone) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacySkillMixMilestoneModifier = steps[index]
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

        func evaluateAll(_ items: [LegacySkillMixMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacySkillMixMilestoneEngine() -> LegacySkillMixMilestoneEngine {
        return LegacySkillMixMilestoneEngine(
            steps: [
                PercentLegacySkillMixMilestoneAdjuster(percent: -19.7),
                CapLegacySkillMixMilestoneAdjuster(cap: 31616.0),
                RoundingLegacySkillMixMilestoneAdjuster(step: 0.5),
                LocaleLegacySkillMixMilestoneAdjuster(factors: ["online": 1.03, "north": 1.39, "east": 1.25]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 1901.7
        )
    }
}
