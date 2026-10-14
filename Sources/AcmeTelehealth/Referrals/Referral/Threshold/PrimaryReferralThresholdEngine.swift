import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary referral threshold calculation.
    protocol PrimaryReferralThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryReferralThreshold, value: Double) -> Double
    }

    final class RoundingPrimaryReferralThresholdAdjuster: PrimaryReferralThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryReferralThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPrimaryReferralThresholdAdjuster: PrimaryReferralThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryReferralThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPrimaryReferralThresholdAdjuster: PrimaryReferralThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryReferralThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelPrimaryReferralThresholdAdjuster: PrimaryReferralThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryReferralThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary referral threshold steps in order and keeps a trace of each.
    final class PrimaryReferralThresholdEngine {
        var steps: [any PrimaryReferralThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryReferralThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryReferralThreshold) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryReferralThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryReferralThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryReferralThresholdEngine() -> PrimaryReferralThresholdEngine {
        return PrimaryReferralThresholdEngine(
            steps: [
                RoundingPrimaryReferralThresholdAdjuster(step: 0.25),
                TieredPrimaryReferralThresholdAdjuster(bounds: [2262.0, 3346.0, 9953.0], rates: [0.92, 1.18, 1.18]),
                MinimumPrimaryReferralThresholdAdjuster(minimum: 19.2),
                LabelPrimaryReferralThresholdAdjuster(factors: ["north": 1.04, "south": 0.73]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 7982.9
        )
    }
}
