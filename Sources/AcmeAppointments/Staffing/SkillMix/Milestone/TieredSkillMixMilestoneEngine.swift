import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered skill mix milestone calculation.
    protocol TieredSkillMixMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: TieredSkillMixMilestone, value: Double) -> Double
    }

    final class FlaggedTieredSkillMixMilestoneAdjuster: TieredSkillMixMilestoneAdjuster {
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

        func adjust(_ item: TieredSkillMixMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentTieredSkillMixMilestoneAdjuster: TieredSkillMixMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredSkillMixMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredSkillMixMilestoneAdjuster: TieredSkillMixMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredSkillMixMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSkillMixMilestoneBudgetOffsetAdjuster: TieredSkillMixMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: TieredSkillMixMilestone, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class RoundingTieredSkillMixMilestoneAdjuster: TieredSkillMixMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredSkillMixMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityTieredSkillMixMilestoneAdjuster: TieredSkillMixMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: TieredSkillMixMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered skill mix milestone steps in order and keeps a trace of each.
    final class TieredSkillMixMilestoneEngine {
        var steps: [any TieredSkillMixMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredSkillMixMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredSkillMixMilestone) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [TieredSkillMixMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredSkillMixMilestoneEngine(_ flags: Kit.Flags.Registry) -> TieredSkillMixMilestoneEngine {
        return TieredSkillMixMilestoneEngine(
            steps: [
                FlaggedTieredSkillMixMilestoneAdjuster(
                    flags: flags,
                    flag: "tiered-skill-mix-milestone-weighted",
                    percent: -9.3
                ),
                PercentTieredSkillMixMilestoneAdjuster(percent: 10.7),
                MinimumTieredSkillMixMilestoneAdjuster(minimum: 19.6),
                TieredSkillMixMilestoneBudgetOffsetAdjuster(weight: 1.35),
                RoundingTieredSkillMixMilestoneAdjuster(step: 0.05),
                FacilityTieredSkillMixMilestoneAdjuster(factors: ["south": 1.23, "north": 1.18]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 63535.2
        )
    }
}
