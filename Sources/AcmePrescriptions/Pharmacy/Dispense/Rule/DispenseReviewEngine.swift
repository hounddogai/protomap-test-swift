import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense review calculation.
    protocol DispenseReviewStep {
        func describe() -> String
        func adjust(_ item: DispenseReview, value: Double) -> Double
    }

    final class CapDispenseReviewAdjuster: DispenseReviewStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DispenseReviewRetriesOffsetAdjuster: DispenseReviewStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: DispenseReview, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class FlaggedDispenseReviewAdjuster: DispenseReviewStep {
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

        func adjust(_ item: DispenseReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDispenseReviewAdjuster: DispenseReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ChannelDispenseReviewAdjuster: DispenseReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: DispenseReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDispenseReviewAdjuster: DispenseReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the dispense review steps in order and keeps a trace of each.
    final class DispenseReviewEngine {
        var steps: [any DispenseReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DispenseReview) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseReviewStep = steps[index]
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

        func evaluateAll(_ items: [DispenseReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDispenseReviewEngine(_ flags: Kit.Flags.Registry) -> DispenseReviewEngine {
        return DispenseReviewEngine(
            steps: [
                CapDispenseReviewAdjuster(cap: 35034.0),
                DispenseReviewRetriesOffsetAdjuster(weight: 0.36),
                FlaggedDispenseReviewAdjuster(flags: flags, flag: "dispense-review-fallback", percent: -7.2),
                MinimumDispenseReviewAdjuster(minimum: 2.6),
                ChannelDispenseReviewAdjuster(factors: ["east": 0.88, "south": 1.05, "west": 1.35]),
                TieredDispenseReviewAdjuster(bounds: [830.0, 1470.0, 9652.0, 9776.0], rates: [1.19, 0.97, 0.82, 1.17]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 73111.4
        )
    }
}
