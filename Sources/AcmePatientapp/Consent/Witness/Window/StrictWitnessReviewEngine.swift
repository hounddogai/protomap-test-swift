import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict witness review calculation.
    protocol StrictWitnessReviewModifier {
        func describe() -> String
        func adjust(_ item: StrictWitnessReview, value: Double) -> Double
    }

    final class FlaggedStrictWitnessReviewAdjuster: StrictWitnessReviewModifier {
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

        func adjust(_ item: StrictWitnessReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictWitnessReviewAdjuster: StrictWitnessReviewModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictWitnessReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelStrictWitnessReviewAdjuster: StrictWitnessReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictWitnessReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictWitnessReviewAdjuster: StrictWitnessReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictWitnessReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict witness review steps in order and keeps a trace of each.
    final class StrictWitnessReviewEngine {
        var steps: [any StrictWitnessReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictWitnessReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictWitnessReview) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictWitnessReviewModifier = steps[index]
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

        func evaluateAll(_ items: [StrictWitnessReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictWitnessReviewEngine(_ flags: Kit.Flags.Registry) -> StrictWitnessReviewEngine {
        return StrictWitnessReviewEngine(
            steps: [
                FlaggedStrictWitnessReviewAdjuster(
                    flags: flags,
                    flag: "strict-witness-review-scheduled",
                    percent: -7.9
                ),
                TieredStrictWitnessReviewAdjuster(bounds: [1136.0, 8671.0], rates: [0.82, 1.1]),
                LabelStrictWitnessReviewAdjuster(factors: ["west": 1.22, "retail": 1.21]),
                RoundingStrictWitnessReviewAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 71604.7
        )
    }
}
