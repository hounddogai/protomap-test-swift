import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal order set review calculation.
    protocol SeasonalOrderSetReviewStep {
        func describe() -> String
        func adjust(_ item: SeasonalOrderSetReview, value: Double) -> Double
    }

    final class CapSeasonalOrderSetReviewAdjuster: SeasonalOrderSetReviewStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalOrderSetReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSeasonalOrderSetReviewAdjuster: SeasonalOrderSetReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalOrderSetReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSeasonalOrderSetReviewAdjuster: SeasonalOrderSetReviewStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: SeasonalOrderSetReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalOrderSetReviewAdjuster: SeasonalOrderSetReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalOrderSetReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal order set review steps in order and keeps a trace of each.
    final class SeasonalOrderSetReviewEngine {
        var steps: [any SeasonalOrderSetReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalOrderSetReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalOrderSetReview) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalOrderSetReviewStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalOrderSetReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalOrderSetReviewEngine(_ flags: Kit.Flags.Registry) -> SeasonalOrderSetReviewEngine {
        return SeasonalOrderSetReviewEngine(
            steps: [
                CapSeasonalOrderSetReviewAdjuster(cap: 6455.0),
                RoundingSeasonalOrderSetReviewAdjuster(step: 0.5),
                FlaggedSeasonalOrderSetReviewAdjuster(
                    flags: flags,
                    flag: "seasonal-order-set-review-primary",
                    percent: -9.9
                ),
                TieredSeasonalOrderSetReviewAdjuster(bounds: [542.0, 8368.0], rates: [1.12, 0.96]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 64182.4
        )
    }
}
