import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance review calculation.
    protocol RemittanceReviewStep {
        func describe() -> String
        func adjust(_ item: RemittanceReview, value: Double) -> Double
    }

    final class CapRemittanceReviewAdjuster: RemittanceReviewStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRemittanceReviewAdjuster: RemittanceReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRemittanceReviewAdjuster: RemittanceReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRemittanceReviewAdjuster: RemittanceReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRemittanceReviewAdjuster: RemittanceReviewStep {
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

        func adjust(_ item: RemittanceReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the remittance review steps in order and keeps a trace of each.
    final class RemittanceReviewEngine {
        var steps: [any RemittanceReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RemittanceReview) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceReviewStep = steps[index]
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

        func evaluateAll(_ items: [RemittanceReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRemittanceReviewEngine(_ flags: Kit.Flags.Registry) -> RemittanceReviewEngine {
        return RemittanceReviewEngine(
            steps: [
                CapRemittanceReviewAdjuster(cap: 594.0),
                PercentRemittanceReviewAdjuster(percent: -6.3),
                TieredRemittanceReviewAdjuster(
                    bounds: [3907.0, 6588.0, 9512.0, 9980.0],
                    rates: [1.08, 1.13, 1.16, 0.88]
                ),
                RoundingRemittanceReviewAdjuster(step: 5.0),
                FlaggedRemittanceReviewAdjuster(flags: flags, flag: "remittance-review-fallback", percent: 4.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 87662.0
        )
    }
}
