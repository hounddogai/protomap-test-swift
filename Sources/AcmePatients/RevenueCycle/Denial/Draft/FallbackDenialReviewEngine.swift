import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback denial review calculation.
    protocol FallbackDenialReviewFactor {
        func describe() -> String
        func adjust(_ item: FallbackDenialReview, value: Double) -> Double
    }

    final class MinimumFallbackDenialReviewAdjuster: FallbackDenialReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackDenialReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredFallbackDenialReviewAdjuster: FallbackDenialReviewFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackDenialReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackDenialReviewDurationMinutesOffsetAdjuster: FallbackDenialReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: FallbackDenialReview, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    /// Runs the fallback denial review steps in order and keeps a trace of each.
    final class FallbackDenialReviewEngine {
        var steps: [any FallbackDenialReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackDenialReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackDenialReview) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackDenialReviewFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackDenialReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackDenialReviewEngine() -> FallbackDenialReviewEngine {
        return FallbackDenialReviewEngine(
            steps: [
                MinimumFallbackDenialReviewAdjuster(minimum: 14.5),
                TieredFallbackDenialReviewAdjuster(bounds: [3361.0, 6512.0, 7349.0], rates: [0.87, 1.01, 1.15]),
                FallbackDenialReviewDurationMinutesOffsetAdjuster(weight: 0.12),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 47324.7
        )
    }
}
