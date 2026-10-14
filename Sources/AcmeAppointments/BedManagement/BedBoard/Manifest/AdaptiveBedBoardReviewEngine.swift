import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive bed board review calculation.
    protocol AdaptiveBedBoardReviewStep {
        func describe() -> String
        func adjust(_ item: AdaptiveBedBoardReview, value: Double) -> Double
    }

    final class UnitAdaptiveBedBoardReviewAdjuster: AdaptiveBedBoardReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: AdaptiveBedBoardReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAdaptiveBedBoardReviewAdjuster: AdaptiveBedBoardReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveBedBoardReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAdaptiveBedBoardReviewAdjuster: AdaptiveBedBoardReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveBedBoardReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveBedBoardReviewAdjuster: AdaptiveBedBoardReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveBedBoardReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAdaptiveBedBoardReviewAdjuster: AdaptiveBedBoardReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveBedBoardReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveBedBoardReviewAdjuster: AdaptiveBedBoardReviewStep {
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

        func adjust(_ item: AdaptiveBedBoardReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive bed board review steps in order and keeps a trace of each.
    final class AdaptiveBedBoardReviewEngine {
        var steps: [any AdaptiveBedBoardReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveBedBoardReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveBedBoardReview) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveBedBoardReviewStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveBedBoardReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveBedBoardReviewEngine(_ flags: Kit.Flags.Registry) -> AdaptiveBedBoardReviewEngine {
        return AdaptiveBedBoardReviewEngine(
            steps: [
                UnitAdaptiveBedBoardReviewAdjuster(factors: ["east": 1.04, "retail": 1.26, "central": 1.2]),
                RoundingAdaptiveBedBoardReviewAdjuster(step: 0.25),
                TieredAdaptiveBedBoardReviewAdjuster(
                    bounds: [1870.0, 4004.0, 6073.0, 9827.0],
                    rates: [1.01, 0.81, 0.89, 0.87]
                ),
                MinimumAdaptiveBedBoardReviewAdjuster(minimum: 32.9),
                PercentAdaptiveBedBoardReviewAdjuster(percent: 0.3),
                FlaggedAdaptiveBedBoardReviewAdjuster(
                    flags: flags,
                    flag: "adaptive-bed-board-review-global",
                    percent: 2.5
                ),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 12717.5
        )
    }
}
