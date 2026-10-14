import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted referral cycle calculation.
    protocol WeightedReferralCycleAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedReferralCycle, value: Double) -> Double
    }

    final class CapWeightedReferralCycleAdjuster: WeightedReferralCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedReferralCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedReferralCycleAdjuster: WeightedReferralCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedReferralCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedReferralCycleAdjuster: WeightedReferralCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedReferralCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumWeightedReferralCycleAdjuster: WeightedReferralCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedReferralCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WeightedReferralCycleExpiresAtOffsetAdjuster: WeightedReferralCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: WeightedReferralCycle, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the weighted referral cycle steps in order and keeps a trace of each.
    final class WeightedReferralCycleEngine {
        var steps: [any WeightedReferralCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedReferralCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedReferralCycle) -> Double {
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

        func evaluateAll(_ items: [WeightedReferralCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedReferralCycleEngine() -> WeightedReferralCycleEngine {
        return WeightedReferralCycleEngine(
            steps: [
                CapWeightedReferralCycleAdjuster(cap: 16818.0),
                TieredWeightedReferralCycleAdjuster(bounds: [1098.0, 2229.0, 2444.0], rates: [1.0, 0.98, 1.16]),
                RoundingWeightedReferralCycleAdjuster(step: 0.05),
                MinimumWeightedReferralCycleAdjuster(minimum: 7.7),
                WeightedReferralCycleExpiresAtOffsetAdjuster(weight: 1.63),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 31747.6
        )
    }
}
