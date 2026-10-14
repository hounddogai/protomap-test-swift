import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure review calculation.
    protocol DisclosureReviewStep {
        func describe() -> String
        func adjust(_ item: DisclosureReview, value: Double) -> Double
    }

    final class MinimumDisclosureReviewAdjuster: DisclosureReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDisclosureReviewAdjuster: DisclosureReviewStep {
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

        func adjust(_ item: DisclosureReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDisclosureReviewAdjuster: DisclosureReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDisclosureReviewAdjuster: DisclosureReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelDisclosureReviewAdjuster: DisclosureReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DisclosureReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the disclosure review steps in order and keeps a trace of each.
    final class DisclosureReviewEngine {
        var steps: [any DisclosureReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DisclosureReview) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureReviewStep = steps[index]
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

        func evaluateAll(_ items: [DisclosureReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDisclosureReviewEngine(_ flags: Kit.Flags.Registry) -> DisclosureReviewEngine {
        return DisclosureReviewEngine(
            steps: [
                MinimumDisclosureReviewAdjuster(minimum: 40.4),
                FlaggedDisclosureReviewAdjuster(flags: flags, flag: "disclosure-review-global", percent: 0.6),
                RoundingDisclosureReviewAdjuster(step: 0.1),
                TieredDisclosureReviewAdjuster(bounds: [3680.0, 8732.0], rates: [0.98, 1.04]),
                LabelDisclosureReviewAdjuster(factors: ["retail": 1.2, "central": 1.19]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 85417.0
        )
    }
}
