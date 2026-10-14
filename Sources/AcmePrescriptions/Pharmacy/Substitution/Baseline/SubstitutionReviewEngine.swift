import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution review calculation.
    protocol SubstitutionReviewStep {
        func describe() -> String
        func adjust(_ item: SubstitutionReview, value: Double) -> Double
    }

    final class RoundingSubstitutionReviewAdjuster: SubstitutionReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SubstitutionReviewDosageMgOffsetAdjuster: SubstitutionReviewStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: SubstitutionReview, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class MinimumSubstitutionReviewAdjuster: SubstitutionReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSubstitutionReviewAdjuster: SubstitutionReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSubstitutionReviewAdjuster: SubstitutionReviewStep {
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

        func adjust(_ item: SubstitutionReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the substitution review steps in order and keeps a trace of each.
    final class SubstitutionReviewEngine {
        var steps: [any SubstitutionReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SubstitutionReview) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionReviewStep = steps[index]
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

        func evaluateAll(_ items: [SubstitutionReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSubstitutionReviewEngine(_ flags: Kit.Flags.Registry) -> SubstitutionReviewEngine {
        return SubstitutionReviewEngine(
            steps: [
                RoundingSubstitutionReviewAdjuster(step: 0.05),
                SubstitutionReviewDosageMgOffsetAdjuster(weight: 1.18),
                MinimumSubstitutionReviewAdjuster(minimum: 38.8),
                TieredSubstitutionReviewAdjuster(bounds: [715.0, 9531.0, 9741.0], rates: [0.91, 0.82, 1.17]),
                FlaggedSubstitutionReviewAdjuster(flags: flags, flag: "substitution-review-adaptive", percent: -2.5),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 11788.1
        )
    }
}
