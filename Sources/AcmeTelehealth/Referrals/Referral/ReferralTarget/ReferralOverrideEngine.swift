import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral override calculation.
    protocol ReferralOverrideModifier {
        func describe() -> String
        func adjust(_ item: ReferralOverride, value: Double) -> Double
    }

    final class TieredReferralOverrideAdjuster: ReferralOverrideModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingReferralOverrideAdjuster: ReferralOverrideModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentReferralOverrideAdjuster: ReferralOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapReferralOverrideAdjuster: ReferralOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferralOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the referral override steps in order and keeps a trace of each.
    final class ReferralOverrideEngine {
        var steps: [any ReferralOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferralOverride) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferralOverrideModifier = steps[index]
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

        func evaluateAll(_ items: [ReferralOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferralOverrideEngine() -> ReferralOverrideEngine {
        return ReferralOverrideEngine(
            steps: [
                TieredReferralOverrideAdjuster(
                    bounds: [1279.0, 6688.0, 6947.0, 9676.0],
                    rates: [1.11, 1.18, 1.14, 1.08]
                ),
                RoundingReferralOverrideAdjuster(step: 1.0),
                PercentReferralOverrideAdjuster(percent: 17.6),
                CapReferralOverrideAdjuster(cap: 18029.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 35023.4
        )
    }
}
