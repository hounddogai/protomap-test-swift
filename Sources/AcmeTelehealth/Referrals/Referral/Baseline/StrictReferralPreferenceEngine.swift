import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the strict referral preference calculation.
    protocol StrictReferralPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: StrictReferralPreference, value: Double) -> Double
    }

    final class MinimumStrictReferralPreferenceAdjuster: StrictReferralPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictReferralPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStrictReferralPreferenceAdjuster: StrictReferralPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictReferralPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapStrictReferralPreferenceAdjuster: StrictReferralPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictReferralPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStrictReferralPreferenceAdjuster: StrictReferralPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictReferralPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict referral preference steps in order and keeps a trace of each.
    final class StrictReferralPreferenceEngine {
        var steps: [any StrictReferralPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictReferralPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictReferralPreference) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictReferralPreferenceAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictReferralPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictReferralPreferenceEngine() -> StrictReferralPreferenceEngine {
        return StrictReferralPreferenceEngine(
            steps: [
                MinimumStrictReferralPreferenceAdjuster(minimum: 34.2),
                TieredStrictReferralPreferenceAdjuster(bounds: [2259.0, 7652.0], rates: [0.91, 0.81]),
                CapStrictReferralPreferenceAdjuster(cap: 5760.0),
                PercentStrictReferralPreferenceAdjuster(percent: -24.5),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 37921.2
        )
    }
}
