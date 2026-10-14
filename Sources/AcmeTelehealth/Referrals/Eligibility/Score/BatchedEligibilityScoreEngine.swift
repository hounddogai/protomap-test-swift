import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched eligibility score calculation.
    protocol BatchedEligibilityScoreStep {
        func describe() -> String
        func adjust(_ item: BatchedEligibilityScore, value: Double) -> Double
    }

    final class PercentBatchedEligibilityScoreAdjuster: BatchedEligibilityScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedEligibilityScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleBatchedEligibilityScoreAdjuster: BatchedEligibilityScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedEligibilityScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedEligibilityScoreAdjuster: BatchedEligibilityScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedEligibilityScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBatchedEligibilityScoreAdjuster: BatchedEligibilityScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedEligibilityScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapBatchedEligibilityScoreAdjuster: BatchedEligibilityScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedEligibilityScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedEligibilityScoreAdjuster: BatchedEligibilityScoreStep {
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

        func adjust(_ item: BatchedEligibilityScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched eligibility score steps in order and keeps a trace of each.
    final class BatchedEligibilityScoreEngine {
        var steps: [any BatchedEligibilityScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedEligibilityScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedEligibilityScore) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedEligibilityScoreStep = steps[index]
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

        func evaluateAll(_ items: [BatchedEligibilityScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedEligibilityScoreEngine(_ flags: Kit.Flags.Registry) -> BatchedEligibilityScoreEngine {
        return BatchedEligibilityScoreEngine(
            steps: [
                PercentBatchedEligibilityScoreAdjuster(percent: 13.3),
                TitleBatchedEligibilityScoreAdjuster(factors: ["retail": 0.72, "north": 1.07, "east": 0.92]),
                RoundingBatchedEligibilityScoreAdjuster(step: 1.0),
                MinimumBatchedEligibilityScoreAdjuster(minimum: 33.9),
                CapBatchedEligibilityScoreAdjuster(cap: 47501.0),
                FlaggedBatchedEligibilityScoreAdjuster(
                    flags: flags,
                    flag: "batched-eligibility-score-primary",
                    percent: -6.2
                ),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 74982.4
        )
    }
}
