import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range review calculation.
    protocol ReferenceRangeReviewAdjuster {
        func describe() -> String
        func adjust(_ item: ReferenceRangeReview, value: Double) -> Double
    }

    final class ReferenceRangeReviewAmountOffsetAdjuster: ReferenceRangeReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ReferenceRangeReview, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class TieredReferenceRangeReviewAdjuster: ReferenceRangeReviewAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumReferenceRangeReviewAdjuster: ReferenceRangeReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingReferenceRangeReviewAdjuster: ReferenceRangeReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the reference range review steps in order and keeps a trace of each.
    final class ReferenceRangeReviewEngine {
        var steps: [any ReferenceRangeReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferenceRangeReview) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ReferenceRangeReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeReviewEngine() -> ReferenceRangeReviewEngine {
        return ReferenceRangeReviewEngine(
            steps: [
                ReferenceRangeReviewAmountOffsetAdjuster(weight: 0.37),
                TieredReferenceRangeReviewAdjuster(bounds: [1075.0, 5038.0, 6123.0], rates: [1.17, 0.83, 0.94]),
                MinimumReferenceRangeReviewAdjuster(minimum: 8.1),
                RoundingReferenceRangeReviewAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 19730.9
        )
    }
}
