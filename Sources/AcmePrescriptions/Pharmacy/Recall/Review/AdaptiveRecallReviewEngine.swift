import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the adaptive recall review calculation.
    protocol AdaptiveRecallReviewStep {
        func describe() -> String
        func adjust(_ item: AdaptiveRecallReview, value: Double) -> Double
    }

    final class FlaggedAdaptiveRecallReviewAdjuster: AdaptiveRecallReviewStep {
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

        func adjust(_ item: AdaptiveRecallReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleAdaptiveRecallReviewAdjuster: AdaptiveRecallReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AdaptiveRecallReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAdaptiveRecallReviewAdjuster: AdaptiveRecallReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveRecallReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive recall review steps in order and keeps a trace of each.
    final class AdaptiveRecallReviewEngine {
        var steps: [any AdaptiveRecallReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRecallReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveRecallReview) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [AdaptiveRecallReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRecallReviewEngine(_ flags: Kit.Flags.Registry) -> AdaptiveRecallReviewEngine {
        return AdaptiveRecallReviewEngine(
            steps: [
                FlaggedAdaptiveRecallReviewAdjuster(
                    flags: flags,
                    flag: "adaptive-recall-review-primary",
                    percent: -5.7
                ),
                TitleAdaptiveRecallReviewAdjuster(factors: ["south": 1.09, "west": 1.32]),
                RoundingAdaptiveRecallReviewAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 25048.5
        )
    }
}
