import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier review calculation.
    protocol CourierReviewAdjuster {
        func describe() -> String
        func adjust(_ item: CourierReview, value: Double) -> Double
    }

    final class RoundingCourierReviewAdjuster: CourierReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCourierReviewAdjuster: CourierReviewAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCourierReviewAdjuster: CourierReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the courier review steps in order and keeps a trace of each.
    final class CourierReviewEngine {
        var steps: [any CourierReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CourierReview) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [CourierReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCourierReviewEngine() -> CourierReviewEngine {
        return CourierReviewEngine(
            steps: [
                RoundingCourierReviewAdjuster(step: 0.1),
                TieredCourierReviewAdjuster(bounds: [2566.0, 4548.0, 7942.0, 9995.0], rates: [0.98, 1.18, 0.98, 0.9]),
                MinimumCourierReviewAdjuster(minimum: 8.5),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 44062.2
        )
    }
}
