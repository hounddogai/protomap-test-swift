import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional denial policy calculation.
    protocol RegionalDenialPolicyFactor {
        func describe() -> String
        func adjust(_ item: RegionalDenialPolicy, value: Double) -> Double
    }

    final class RegionRegionalDenialPolicyAdjuster: RegionalDenialPolicyFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RegionalDenialPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalDenialPolicyAdjuster: RegionalDenialPolicyFactor {
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

        func adjust(_ item: RegionalDenialPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalDenialPolicyAdjuster: RegionalDenialPolicyFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalDenialPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRegionalDenialPolicyAdjuster: RegionalDenialPolicyFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalDenialPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional denial policy steps in order and keeps a trace of each.
    final class RegionalDenialPolicyEngine {
        var steps: [any RegionalDenialPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalDenialPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalDenialPolicy) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [RegionalDenialPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalDenialPolicyEngine(_ flags: Kit.Flags.Registry) -> RegionalDenialPolicyEngine {
        return RegionalDenialPolicyEngine(
            steps: [
                RegionRegionalDenialPolicyAdjuster(factors: ["central": 0.96]),
                FlaggedRegionalDenialPolicyAdjuster(flags: flags, flag: "regional-denial-policy-tiered", percent: 6.8),
                TieredRegionalDenialPolicyAdjuster(bounds: [6883.0, 9252.0, 9619.0], rates: [1.02, 0.98, 1.04]),
                PercentRegionalDenialPolicyAdjuster(percent: -9.8),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 30224.7
        )
    }
}
