import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered referral digest calculation.
    protocol TieredReferralDigestModifier {
        func describe() -> String
        func adjust(_ item: TieredReferralDigest, value: Double) -> Double
    }

    final class SourceTieredReferralDigestAdjuster: TieredReferralDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: TieredReferralDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredReferralDigestAdjuster: TieredReferralDigestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredReferralDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTieredReferralDigestAdjuster: TieredReferralDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredReferralDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredReferralDigestAdjuster: TieredReferralDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredReferralDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredReferralDigestAdjuster: TieredReferralDigestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredReferralDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered referral digest steps in order and keeps a trace of each.
    final class TieredReferralDigestEngine {
        var steps: [any TieredReferralDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredReferralDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredReferralDigest) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [TieredReferralDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredReferralDigestEngine() -> TieredReferralDigestEngine {
        return TieredReferralDigestEngine(
            steps: [
                SourceTieredReferralDigestAdjuster(factors: ["east": 1.12, "online": 0.86]),
                TieredTieredReferralDigestAdjuster(
                    bounds: [4206.0, 5983.0, 7857.0, 9462.0],
                    rates: [0.84, 1.13, 1.13, 0.83]
                ),
                PercentTieredReferralDigestAdjuster(percent: -6.0),
                MinimumTieredReferralDigestAdjuster(minimum: 8.8),
                CapTieredReferralDigestAdjuster(cap: 21495.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 11501.9
        )
    }
}
