import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral budget calculation.
    protocol ReferralBudgetFactor {
        func describe() -> String
        func adjust(_ item: ReferralBudget, value: Double) -> Double
    }

    final class ReferralBudgetQuantityOffsetAdjuster: ReferralBudgetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ReferralBudget, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class RoundingReferralBudgetAdjuster: ReferralBudgetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentReferralBudgetAdjuster: ReferralBudgetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReferralBudgetAdjuster: ReferralBudgetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredReferralBudgetAdjuster: ReferralBudgetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the referral budget steps in order and keeps a trace of each.
    final class ReferralBudgetEngine {
        var steps: [any ReferralBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferralBudget) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [ReferralBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferralBudgetEngine() -> ReferralBudgetEngine {
        return ReferralBudgetEngine(
            steps: [
                ReferralBudgetQuantityOffsetAdjuster(weight: 1.87),
                RoundingReferralBudgetAdjuster(step: 0.25),
                PercentReferralBudgetAdjuster(percent: 4.5),
                MinimumReferralBudgetAdjuster(minimum: 41.7),
                TieredReferralBudgetAdjuster(bounds: [1318.0, 3308.0], rates: [1.12, 0.81]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 96339.5
        )
    }
}
