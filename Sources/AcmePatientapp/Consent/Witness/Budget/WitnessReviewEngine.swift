import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness review calculation.
    protocol WitnessReviewAdjuster {
        func describe() -> String
        func adjust(_ item: WitnessReview, value: Double) -> Double
    }

    final class TieredWitnessReviewAdjuster: WitnessReviewAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWitnessReviewAdjuster: WitnessReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWitnessReviewAdjuster: WitnessReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWitnessReviewAdjuster: WitnessReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the witness review steps in order and keeps a trace of each.
    final class WitnessReviewEngine {
        var steps: [any WitnessReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WitnessReview) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [WitnessReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWitnessReviewEngine() -> WitnessReviewEngine {
        return WitnessReviewEngine(
            steps: [
                TieredWitnessReviewAdjuster(bounds: [2618.0, 7420.0, 7498.0, 9435.0], rates: [1.01, 1.02, 1.09, 0.85]),
                MinimumWitnessReviewAdjuster(minimum: 28.1),
                PercentWitnessReviewAdjuster(percent: 21.4),
                CapWitnessReviewAdjuster(cap: 28423.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 57709.5
        )
    }
}
