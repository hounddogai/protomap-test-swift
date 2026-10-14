import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy referral target calculation.
    protocol LegacyReferralTargetStep {
        func describe() -> String
        func adjust(_ item: LegacyReferralTarget, value: Double) -> Double
    }

    final class TieredLegacyReferralTargetAdjuster: LegacyReferralTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyReferralTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LegacyReferralTargetEndsAtOffsetAdjuster: LegacyReferralTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: LegacyReferralTarget, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumLegacyReferralTargetAdjuster: LegacyReferralTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyReferralTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy referral target steps in order and keeps a trace of each.
    final class LegacyReferralTargetEngine {
        var steps: [any LegacyReferralTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyReferralTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyReferralTarget) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyReferralTargetStep = steps[index]
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

        func evaluateAll(_ items: [LegacyReferralTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyReferralTargetEngine() -> LegacyReferralTargetEngine {
        return LegacyReferralTargetEngine(
            steps: [
                TieredLegacyReferralTargetAdjuster(
                    bounds: [2362.0, 2446.0, 5154.0, 6105.0],
                    rates: [1.14, 0.89, 1.12, 1.15]
                ),
                LegacyReferralTargetEndsAtOffsetAdjuster(weight: 1.21),
                MinimumLegacyReferralTargetAdjuster(minimum: 23.5),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 20143.3
        )
    }
}
