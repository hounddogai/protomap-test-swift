import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched credential review calculation.
    protocol BatchedCredentialReviewModifier {
        func describe() -> String
        func adjust(_ item: BatchedCredentialReview, value: Double) -> Double
    }

    final class BatchedCredentialReviewUpdatedAtOffsetAdjuster: BatchedCredentialReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: BatchedCredentialReview, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class TieredBatchedCredentialReviewAdjuster: BatchedCredentialReviewModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedCredentialReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBatchedCredentialReviewAdjuster: BatchedCredentialReviewModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedCredentialReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapBatchedCredentialReviewAdjuster: BatchedCredentialReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedCredentialReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the batched credential review steps in order and keeps a trace of each.
    final class BatchedCredentialReviewEngine {
        var steps: [any BatchedCredentialReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCredentialReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedCredentialReview) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [BatchedCredentialReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedCredentialReviewEngine() -> BatchedCredentialReviewEngine {
        return BatchedCredentialReviewEngine(
            steps: [
                BatchedCredentialReviewUpdatedAtOffsetAdjuster(weight: 1.58),
                TieredBatchedCredentialReviewAdjuster(
                    bounds: [1722.0, 2302.0, 3926.0, 6266.0],
                    rates: [1.02, 0.82, 1.14, 0.92]
                ),
                MinimumBatchedCredentialReviewAdjuster(minimum: 17.8),
                CapBatchedCredentialReviewAdjuster(cap: 29552.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 11973.5
        )
    }
}
