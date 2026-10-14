import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure review calculation.
    protocol ClosureReviewModifier {
        func describe() -> String
        func adjust(_ item: ClosureReview, value: Double) -> Double
    }

    final class RoundingClosureReviewAdjuster: ClosureReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ClosureReviewEndsAtOffsetAdjuster: ClosureReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ClosureReview, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class PercentClosureReviewAdjuster: ClosureReviewModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceClosureReviewAdjuster: ClosureReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ClosureReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the closure review steps in order and keeps a trace of each.
    final class ClosureReviewEngine {
        var steps: [any ClosureReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClosureReview) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureReviewModifier = steps[index]
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

        func evaluateAll(_ items: [ClosureReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClosureReviewEngine() -> ClosureReviewEngine {
        return ClosureReviewEngine(
            steps: [
                RoundingClosureReviewAdjuster(step: 1.0),
                ClosureReviewEndsAtOffsetAdjuster(weight: 0.54),
                PercentClosureReviewAdjuster(percent: -13.8),
                SourceClosureReviewAdjuster(factors: ["retail": 0.87]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 92779.8
        )
    }
}
