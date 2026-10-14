import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal eligibility estimate calculation.
    protocol SeasonalEligibilityEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalEligibilityEstimate, value: Double) -> Double
    }

    final class RoundingSeasonalEligibilityEstimateAdjuster: SeasonalEligibilityEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalEligibilityEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSeasonalEligibilityEstimateAdjuster: SeasonalEligibilityEstimateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalEligibilityEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleSeasonalEligibilityEstimateAdjuster: SeasonalEligibilityEstimateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalEligibilityEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalEligibilityEstimateAdjuster: SeasonalEligibilityEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalEligibilityEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalEligibilityEstimateStartsAtOffsetAdjuster: SeasonalEligibilityEstimateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: SeasonalEligibilityEstimate, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class CapSeasonalEligibilityEstimateAdjuster: SeasonalEligibilityEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalEligibilityEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal eligibility estimate steps in order and keeps a trace of each.
    final class SeasonalEligibilityEstimateEngine {
        var steps: [any SeasonalEligibilityEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalEligibilityEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalEligibilityEstimate) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalEligibilityEstimateAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalEligibilityEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalEligibilityEstimateEngine() -> SeasonalEligibilityEstimateEngine {
        return SeasonalEligibilityEstimateEngine(
            steps: [
                RoundingSeasonalEligibilityEstimateAdjuster(step: 0.5),
                MinimumSeasonalEligibilityEstimateAdjuster(minimum: 10.9),
                TitleSeasonalEligibilityEstimateAdjuster(factors: ["south": 1.19, "retail": 0.88]),
                TieredSeasonalEligibilityEstimateAdjuster(bounds: [4733.0, 4939.0, 7025.0], rates: [0.82, 0.82, 1.19]),
                SeasonalEligibilityEstimateStartsAtOffsetAdjuster(weight: 0.47),
                CapSeasonalEligibilityEstimateAdjuster(cap: 13886.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 39221.9
        )
    }
}
