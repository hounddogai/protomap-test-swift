import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding review calculation.
    protocol RoundingReviewStep {
        func describe() -> String
        func adjust(_ item: RoundingReview, value: Double) -> Double
    }

    final class PercentRoundingReviewAdjuster: RoundingReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRoundingReviewAdjuster: RoundingReviewStep {
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

        func adjust(_ item: RoundingReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRoundingReviewAdjuster: RoundingReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rounding review steps in order and keeps a trace of each.
    final class RoundingReviewEngine {
        var steps: [any RoundingReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RoundingReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingReviewStep = steps[index]
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

        func evaluateAll(_ items: [RoundingReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRoundingReviewEngine(_ flags: Kit.Flags.Registry) -> RoundingReviewEngine {
        return RoundingReviewEngine(
            steps: [
                PercentRoundingReviewAdjuster(percent: 23.4),
                FlaggedRoundingReviewAdjuster(flags: flags, flag: "rounding-review-seasonal", percent: 6.9),
                RoundingRoundingReviewAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 80368.3
        )
    }
}
