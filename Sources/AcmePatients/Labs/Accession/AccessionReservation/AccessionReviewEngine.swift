import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession review calculation.
    protocol AccessionReviewStep {
        func describe() -> String
        func adjust(_ item: AccessionReview, value: Double) -> Double
    }

    final class CapAccessionReviewAdjuster: AccessionReviewStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAccessionReviewAdjuster: AccessionReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAccessionReviewAdjuster: AccessionReviewStep {
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

        func adjust(_ item: AccessionReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAccessionReviewAdjuster: AccessionReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the accession review steps in order and keeps a trace of each.
    final class AccessionReviewEngine {
        var steps: [any AccessionReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AccessionReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionReviewStep = steps[index]
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

        func evaluateAll(_ items: [AccessionReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAccessionReviewEngine(_ flags: Kit.Flags.Registry) -> AccessionReviewEngine {
        return AccessionReviewEngine(
            steps: [
                CapAccessionReviewAdjuster(cap: 17847.0),
                TieredAccessionReviewAdjuster(bounds: [4273.0, 6193.0], rates: [1.06, 0.96]),
                FlaggedAccessionReviewAdjuster(flags: flags, flag: "accession-review-scheduled", percent: 3.6),
                MinimumAccessionReviewAdjuster(minimum: 18.1),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 71725.7
        )
    }
}
