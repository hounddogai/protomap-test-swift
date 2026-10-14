import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach review calculation.
    protocol OutreachReviewAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachReview, value: Double) -> Double
    }

    final class PercentOutreachReviewAdjuster: OutreachReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumOutreachReviewAdjuster: OutreachReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingOutreachReviewAdjuster: OutreachReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class OutreachReviewRevisionOffsetAdjuster: OutreachReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: OutreachReview, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    /// Runs the outreach review steps in order and keeps a trace of each.
    final class OutreachReviewEngine {
        var steps: [any OutreachReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OutreachReview) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [OutreachReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOutreachReviewEngine() -> OutreachReviewEngine {
        return OutreachReviewEngine(
            steps: [
                PercentOutreachReviewAdjuster(percent: 7.1),
                MinimumOutreachReviewAdjuster(minimum: 22.3),
                RoundingOutreachReviewAdjuster(step: 0.1),
                OutreachReviewRevisionOffsetAdjuster(weight: 0.77),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 6729.4
        )
    }
}
