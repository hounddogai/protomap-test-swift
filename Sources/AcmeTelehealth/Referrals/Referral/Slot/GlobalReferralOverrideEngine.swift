import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global referral override calculation.
    protocol GlobalReferralOverrideStep {
        func describe() -> String
        func adjust(_ item: GlobalReferralOverride, value: Double) -> Double
    }

    final class PercentGlobalReferralOverrideAdjuster: GlobalReferralOverrideStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalReferralOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalReferralOverrideAdjuster: GlobalReferralOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalReferralOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredGlobalReferralOverrideAdjuster: GlobalReferralOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalReferralOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingGlobalReferralOverrideAdjuster: GlobalReferralOverrideStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalReferralOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global referral override steps in order and keeps a trace of each.
    final class GlobalReferralOverrideEngine {
        var steps: [any GlobalReferralOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalReferralOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalReferralOverride) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [GlobalReferralOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalReferralOverrideEngine() -> GlobalReferralOverrideEngine {
        return GlobalReferralOverrideEngine(
            steps: [
                PercentGlobalReferralOverrideAdjuster(percent: -17.7),
                CapGlobalReferralOverrideAdjuster(cap: 20725.0),
                TieredGlobalReferralOverrideAdjuster(
                    bounds: [1072.0, 2158.0, 7702.0, 9042.0],
                    rates: [1.15, 1.15, 1.17, 0.82]
                ),
                RoundingGlobalReferralOverrideAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 81804.5
        )
    }
}
