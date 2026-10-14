import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral profile calculation.
    protocol ReferralProfileModifier {
        func describe() -> String
        func adjust(_ item: ReferralProfile, value: Double) -> Double
    }

    final class TieredReferralProfileAdjuster: ReferralProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumReferralProfileAdjuster: ReferralProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelReferralProfileAdjuster: ReferralProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ReferralProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ReferralProfileEndsAtOffsetAdjuster: ReferralProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ReferralProfile, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the referral profile steps in order and keeps a trace of each.
    final class ReferralProfileEngine {
        var steps: [any ReferralProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferralProfile) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralProfileModifier = steps[index]
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

        func evaluateAll(_ items: [ReferralProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferralProfileEngine() -> ReferralProfileEngine {
        return ReferralProfileEngine(
            steps: [
                TieredReferralProfileAdjuster(
                    bounds: [581.0, 1712.0, 3318.0, 3793.0],
                    rates: [0.84, 1.14, 0.87, 0.86]
                ),
                MinimumReferralProfileAdjuster(minimum: 30.4),
                LabelReferralProfileAdjuster(factors: ["retail": 0.78]),
                ReferralProfileEndsAtOffsetAdjuster(weight: 1.97),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 55600.4
        )
    }
}
