import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation policy calculation.
    protocol RevocationPolicyStep {
        func describe() -> String
        func adjust(_ item: RevocationPolicy, value: Double) -> Double
    }

    final class SegmentRevocationPolicyAdjuster: RevocationPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: RevocationPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRevocationPolicyAdjuster: RevocationPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RevocationPolicyDiscountOffsetAdjuster: RevocationPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: RevocationPolicy, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class FlaggedRevocationPolicyAdjuster: RevocationPolicyStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RevocationPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRevocationPolicyAdjuster: RevocationPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRevocationPolicyAdjuster: RevocationPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the revocation policy steps in order and keeps a trace of each.
    final class RevocationPolicyEngine {
        var steps: [any RevocationPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RevocationPolicy) -> Double {
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

        func evaluateAll(_ items: [RevocationPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRevocationPolicyEngine(_ flags: Kit.Flags.Registry) -> RevocationPolicyEngine {
        return RevocationPolicyEngine(
            steps: [
                SegmentRevocationPolicyAdjuster(factors: ["north": 1.39, "south": 0.8]),
                MinimumRevocationPolicyAdjuster(minimum: 29.0),
                RevocationPolicyDiscountOffsetAdjuster(weight: 1.6),
                FlaggedRevocationPolicyAdjuster(flags: flags, flag: "revocation-policy-adaptive", percent: 7.4),
                PercentRevocationPolicyAdjuster(percent: -2.6),
                TieredRevocationPolicyAdjuster(
                    bounds: [1287.0, 3492.0, 5065.0, 9291.0],
                    rates: [0.91, 0.98, 0.97, 1.16]
                ),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 13467.9
        )
    }
}
