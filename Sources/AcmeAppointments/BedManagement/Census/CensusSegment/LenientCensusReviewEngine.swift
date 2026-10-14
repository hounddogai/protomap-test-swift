import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient census review calculation.
    protocol LenientCensusReviewStep {
        func describe() -> String
        func adjust(_ item: LenientCensusReview, value: Double) -> Double
    }

    final class CapLenientCensusReviewAdjuster: LenientCensusReviewStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientCensusReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientCensusReviewAdjuster: LenientCensusReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientCensusReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientCensusReviewAdjuster: LenientCensusReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCensusReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLenientCensusReviewAdjuster: LenientCensusReviewStep {
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

        func adjust(_ item: LenientCensusReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientCensusReviewCeilingOffsetAdjuster: LenientCensusReviewStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: LenientCensusReview, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class MinimumLenientCensusReviewAdjuster: LenientCensusReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCensusReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient census review steps in order and keeps a trace of each.
    final class LenientCensusReviewEngine {
        var steps: [any LenientCensusReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCensusReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCensusReview) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientCensusReviewStep = steps[index]
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

        func evaluateAll(_ items: [LenientCensusReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCensusReviewEngine(_ flags: Kit.Flags.Registry) -> LenientCensusReviewEngine {
        return LenientCensusReviewEngine(
            steps: [
                CapLenientCensusReviewAdjuster(cap: 40367.0),
                PercentLenientCensusReviewAdjuster(percent: -13.0),
                RoundingLenientCensusReviewAdjuster(step: 5.0),
                FlaggedLenientCensusReviewAdjuster(flags: flags, flag: "lenient-census-review-legacy", percent: 3.3),
                LenientCensusReviewCeilingOffsetAdjuster(weight: 0.82),
                MinimumLenientCensusReviewAdjuster(minimum: 8.9),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 98379.9
        )
    }
}
