import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the capped skill mix cycle calculation.
    protocol CappedSkillMixCycleFactor {
        func describe() -> String
        func adjust(_ item: CappedSkillMixCycle, value: Double) -> Double
    }

    final class RoundingCappedSkillMixCycleAdjuster: CappedSkillMixCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedSkillMixCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCappedSkillMixCycleAdjuster: CappedSkillMixCycleFactor {
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

        func adjust(_ item: CappedSkillMixCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedSkillMixCycleAdjuster: CappedSkillMixCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedSkillMixCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCappedSkillMixCycleAdjuster: CappedSkillMixCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedSkillMixCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedSkillMixCycleAdjuster: CappedSkillMixCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedSkillMixCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped skill mix cycle steps in order and keeps a trace of each.
    final class CappedSkillMixCycleEngine {
        var steps: [any CappedSkillMixCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedSkillMixCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedSkillMixCycle) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedSkillMixCycleFactor = steps[index]
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

        func evaluateAll(_ items: [CappedSkillMixCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedSkillMixCycleEngine(_ flags: Kit.Flags.Registry) -> CappedSkillMixCycleEngine {
        return CappedSkillMixCycleEngine(
            steps: [
                RoundingCappedSkillMixCycleAdjuster(step: 5.0),
                FlaggedCappedSkillMixCycleAdjuster(
                    flags: flags,
                    flag: "capped-skill-mix-cycle-scheduled",
                    percent: -1.3
                ),
                TieredCappedSkillMixCycleAdjuster(bounds: [929.0, 7224.0, 9550.0], rates: [1.12, 1.11, 1.19]),
                PercentCappedSkillMixCycleAdjuster(percent: -5.7),
                MinimumCappedSkillMixCycleAdjuster(minimum: 25.5),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 4345.5
        )
    }
}
