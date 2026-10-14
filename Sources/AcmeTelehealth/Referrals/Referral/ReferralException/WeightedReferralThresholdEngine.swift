import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted referral threshold calculation.
    protocol WeightedReferralThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedReferralThreshold, value: Double) -> Double
    }

    final class TieredWeightedReferralThresholdAdjuster: WeightedReferralThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedReferralThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedReferralThresholdAdjuster: WeightedReferralThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedReferralThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedReferralThresholdAdjuster: WeightedReferralThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedReferralThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WeightedReferralThresholdRatioOffsetAdjuster: WeightedReferralThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: WeightedReferralThreshold, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the weighted referral threshold steps in order and keeps a trace of each.
    final class WeightedReferralThresholdEngine {
        var steps: [any WeightedReferralThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedReferralThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedReferralThreshold) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedReferralThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedReferralThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedReferralThresholdEngine() -> WeightedReferralThresholdEngine {
        return WeightedReferralThresholdEngine(
            steps: [
                TieredWeightedReferralThresholdAdjuster(bounds: [744.0, 4934.0, 4950.0], rates: [0.86, 1.14, 0.8]),
                RoundingWeightedReferralThresholdAdjuster(step: 0.5),
                CapWeightedReferralThresholdAdjuster(cap: 42511.0),
                WeightedReferralThresholdRatioOffsetAdjuster(weight: 0.84),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 55472.4
        )
    }
}
