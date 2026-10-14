import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority review calculation.
    protocol PriorityReviewModifier {
        func describe() -> String
        func adjust(_ item: PriorityReview, value: Double) -> Double
    }

    final class CategoryPriorityReviewAdjuster: PriorityReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PriorityReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PriorityReviewCeilingOffsetAdjuster: PriorityReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: PriorityReview, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class TieredPriorityReviewAdjuster: PriorityReviewModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the priority review steps in order and keeps a trace of each.
    final class PriorityReviewEngine {
        var steps: [any PriorityReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PriorityReview) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityReviewModifier = steps[index]
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

        func evaluateAll(_ items: [PriorityReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPriorityReviewEngine() -> PriorityReviewEngine {
        return PriorityReviewEngine(
            steps: [
                CategoryPriorityReviewAdjuster(factors: ["west": 1.16, "central": 1.27, "retail": 0.9]),
                PriorityReviewCeilingOffsetAdjuster(weight: 1.6),
                TieredPriorityReviewAdjuster(bounds: [2236.0, 2375.0, 8715.0], rates: [1.06, 1.18, 0.87]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 50262.3
        )
    }
}
