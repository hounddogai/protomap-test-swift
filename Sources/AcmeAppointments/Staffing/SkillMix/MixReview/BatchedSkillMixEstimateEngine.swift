import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched skill mix estimate calculation.
    protocol BatchedSkillMixEstimateStep {
        func describe() -> String
        func adjust(_ item: BatchedSkillMixEstimate, value: Double) -> Double
    }

    final class FlaggedBatchedSkillMixEstimateAdjuster: BatchedSkillMixEstimateStep {
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

        func adjust(_ item: BatchedSkillMixEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentBatchedSkillMixEstimateAdjuster: BatchedSkillMixEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedSkillMixEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedSkillMixEstimateAdjuster: BatchedSkillMixEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedSkillMixEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched skill mix estimate steps in order and keeps a trace of each.
    final class BatchedSkillMixEstimateEngine {
        var steps: [any BatchedSkillMixEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSkillMixEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedSkillMixEstimate) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [BatchedSkillMixEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedSkillMixEstimateEngine(_ flags: Kit.Flags.Registry) -> BatchedSkillMixEstimateEngine {
        return BatchedSkillMixEstimateEngine(
            steps: [
                FlaggedBatchedSkillMixEstimateAdjuster(
                    flags: flags,
                    flag: "batched-skill-mix-estimate-global",
                    percent: -1.7
                ),
                PercentBatchedSkillMixEstimateAdjuster(percent: 16.4),
                MinimumBatchedSkillMixEstimateAdjuster(minimum: 28.1),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 68449.5
        )
    }
}
