import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the adaptive dispense review calculation.
    protocol AdaptiveDispenseReviewModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveDispenseReview, value: Double) -> Double
    }

    final class AdaptiveDispenseReviewAmountOffsetAdjuster: AdaptiveDispenseReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: AdaptiveDispenseReview, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingAdaptiveDispenseReviewAdjuster: AdaptiveDispenseReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveDispenseReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapAdaptiveDispenseReviewAdjuster: AdaptiveDispenseReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveDispenseReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAdaptiveDispenseReviewAdjuster: AdaptiveDispenseReviewModifier {
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

        func adjust(_ item: AdaptiveDispenseReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveDispenseReviewAdjuster: AdaptiveDispenseReviewModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveDispenseReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive dispense review steps in order and keeps a trace of each.
    final class AdaptiveDispenseReviewEngine {
        var steps: [any AdaptiveDispenseReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveDispenseReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveDispenseReview) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [AdaptiveDispenseReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveDispenseReviewEngine(_ flags: Kit.Flags.Registry) -> AdaptiveDispenseReviewEngine {
        return AdaptiveDispenseReviewEngine(
            steps: [
                AdaptiveDispenseReviewAmountOffsetAdjuster(weight: 0.03),
                RoundingAdaptiveDispenseReviewAdjuster(step: 0.25),
                CapAdaptiveDispenseReviewAdjuster(cap: 5738.0),
                FlaggedAdaptiveDispenseReviewAdjuster(
                    flags: flags,
                    flag: "adaptive-dispense-review-lenient",
                    percent: 6.0
                ),
                TieredAdaptiveDispenseReviewAdjuster(bounds: [2009.0, 3891.0, 8703.0], rates: [1.14, 1.09, 1.01]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 37627.7
        )
    }
}
