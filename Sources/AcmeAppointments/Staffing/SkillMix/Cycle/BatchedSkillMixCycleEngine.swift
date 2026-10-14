import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched skill mix cycle calculation.
    protocol BatchedSkillMixCycleFactor {
        func describe() -> String
        func adjust(_ item: BatchedSkillMixCycle, value: Double) -> Double
    }

    final class MinimumBatchedSkillMixCycleAdjuster: BatchedSkillMixCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedSkillMixCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBatchedSkillMixCycleAdjuster: BatchedSkillMixCycleFactor {
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

        func adjust(_ item: BatchedSkillMixCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleBatchedSkillMixCycleAdjuster: BatchedSkillMixCycleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedSkillMixCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedSkillMixCycleAdjuster: BatchedSkillMixCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedSkillMixCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredBatchedSkillMixCycleAdjuster: BatchedSkillMixCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedSkillMixCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched skill mix cycle steps in order and keeps a trace of each.
    final class BatchedSkillMixCycleEngine {
        var steps: [any BatchedSkillMixCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSkillMixCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedSkillMixCycle) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [BatchedSkillMixCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedSkillMixCycleEngine(_ flags: Kit.Flags.Registry) -> BatchedSkillMixCycleEngine {
        return BatchedSkillMixCycleEngine(
            steps: [
                MinimumBatchedSkillMixCycleAdjuster(minimum: 28.7),
                FlaggedBatchedSkillMixCycleAdjuster(
                    flags: flags,
                    flag: "batched-skill-mix-cycle-legacy",
                    percent: -1.6
                ),
                TitleBatchedSkillMixCycleAdjuster(factors: ["west": 1.23, "central": 1.07, "south": 0.9]),
                RoundingBatchedSkillMixCycleAdjuster(step: 0.5),
                TieredBatchedSkillMixCycleAdjuster(bounds: [1605.0, 2306.0], rates: [0.99, 1.19]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 17314.3
        )
    }
}
