import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral digest calculation.
    protocol ReferralDigestAdjuster {
        func describe() -> String
        func adjust(_ item: ReferralDigest, value: Double) -> Double
    }

    final class MinimumReferralDigestAdjuster: ReferralDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelReferralDigestAdjuster: ReferralDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ReferralDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ReferralDigestRateOffsetAdjuster: ReferralDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ReferralDigest, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the referral digest steps in order and keeps a trace of each.
    final class ReferralDigestEngine {
        var steps: [any ReferralDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferralDigest) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [ReferralDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferralDigestEngine() -> ReferralDigestEngine {
        return ReferralDigestEngine(
            steps: [
                MinimumReferralDigestAdjuster(minimum: 20.2),
                LabelReferralDigestAdjuster(factors: ["south": 0.9, "north": 1.32]),
                ReferralDigestRateOffsetAdjuster(weight: 1.98),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 17873.8
        )
    }
}
