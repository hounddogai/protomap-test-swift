import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional slot review calculation.
    protocol RegionalSlotReviewStep {
        func describe() -> String
        func adjust(_ item: RegionalSlotReview, value: Double) -> Double
    }

    final class TieredRegionalSlotReviewAdjuster: RegionalSlotReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalSlotReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionalSlotReviewAttemptsOffsetAdjuster: RegionalSlotReviewStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: RegionalSlotReview, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class PercentRegionalSlotReviewAdjuster: RegionalSlotReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalSlotReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional slot review steps in order and keeps a trace of each.
    final class RegionalSlotReviewEngine {
        var steps: [any RegionalSlotReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalSlotReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalSlotReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalSlotReviewStep = steps[index]
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

        func evaluateAll(_ items: [RegionalSlotReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalSlotReviewEngine() -> RegionalSlotReviewEngine {
        return RegionalSlotReviewEngine(
            steps: [
                TieredRegionalSlotReviewAdjuster(
                    bounds: [1274.0, 4620.0, 5793.0, 6395.0],
                    rates: [1.13, 0.89, 0.83, 0.97]
                ),
                RegionalSlotReviewAttemptsOffsetAdjuster(weight: 1.81),
                PercentRegionalSlotReviewAdjuster(percent: 18.5),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 66368.0
        )
    }
}
