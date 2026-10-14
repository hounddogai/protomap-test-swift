import AcmePlatform
import Foundation

extension Labs {
    /// One step of the tiered reference range review calculation.
    protocol RangeAssignmentTieredReferenceRangeReviewAdjuster {
        func describe() -> String
        func adjust(_ item: TieredReferenceRangeReview, value: Double) -> Double
    }

    final class RoundingTieredReferenceRangeReviewAdjuster: RangeAssignmentTieredReferenceRangeReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredReferenceRangeReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentTieredReferenceRangeReviewAdjuster: RangeAssignmentTieredReferenceRangeReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredReferenceRangeReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredReferenceRangeReviewAdjuster: RangeAssignmentTieredReferenceRangeReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredReferenceRangeReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredReferenceRangeReviewAdjuster: RangeAssignmentTieredReferenceRangeReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredReferenceRangeReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered reference range review steps in order and keeps a trace of each.
    final class TieredReferenceRangeReviewEngine {
        var steps: [any RangeAssignmentTieredReferenceRangeReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RangeAssignmentTieredReferenceRangeReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredReferenceRangeReview) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RangeAssignmentTieredReferenceRangeReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredReferenceRangeReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredReferenceRangeReviewEngine() -> TieredReferenceRangeReviewEngine {
        return TieredReferenceRangeReviewEngine(
            steps: [
                RoundingTieredReferenceRangeReviewAdjuster(step: 0.25),
                PercentTieredReferenceRangeReviewAdjuster(percent: 0.8),
                CapTieredReferenceRangeReviewAdjuster(cap: 25598.0),
                MinimumTieredReferenceRangeReviewAdjuster(minimum: 49.1),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 55088.3
        )
    }
}
