import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary study review calculation.
    protocol PrimaryStudyReviewAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryStudyReview, value: Double) -> Double
    }

    final class FlaggedPrimaryStudyReviewAdjuster: PrimaryStudyReviewAdjuster {
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

        func adjust(_ item: PrimaryStudyReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryStudyReviewAdjuster: PrimaryStudyReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryStudyReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPrimaryStudyReviewAdjuster: PrimaryStudyReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryStudyReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PrimaryStudyReviewAttemptsOffsetAdjuster: PrimaryStudyReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: PrimaryStudyReview, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the primary study review steps in order and keeps a trace of each.
    final class PrimaryStudyReviewEngine {
        var steps: [any PrimaryStudyReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryStudyReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryStudyReview) -> Double {
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

        func evaluateAll(_ items: [PrimaryStudyReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryStudyReviewEngine(_ flags: Kit.Flags.Registry) -> PrimaryStudyReviewEngine {
        return PrimaryStudyReviewEngine(
            steps: [
                FlaggedPrimaryStudyReviewAdjuster(flags: flags, flag: "primary-study-review-weighted", percent: -2.1),
                RoundingPrimaryStudyReviewAdjuster(step: 0.05),
                CapPrimaryStudyReviewAdjuster(cap: 48548.0),
                PrimaryStudyReviewAttemptsOffsetAdjuster(weight: 0.27),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 56674.7
        )
    }
}
