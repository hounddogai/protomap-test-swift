import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling eligibility variance calculation.
    protocol RollingEligibilityVarianceStep {
        func describe() -> String
        func adjust(_ item: RollingEligibilityVariance, value: Double) -> Double
    }

    final class FlaggedRollingEligibilityVarianceAdjuster: RollingEligibilityVarianceStep {
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

        func adjust(_ item: RollingEligibilityVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingEligibilityVarianceQuantityOffsetAdjuster: RollingEligibilityVarianceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: RollingEligibilityVariance, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class PercentRollingEligibilityVarianceAdjuster: RollingEligibilityVarianceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingEligibilityVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRollingEligibilityVarianceAdjuster: RollingEligibilityVarianceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RollingEligibilityVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingEligibilityVarianceAdjuster: RollingEligibilityVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingEligibilityVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling eligibility variance steps in order and keeps a trace of each.
    final class RollingEligibilityVarianceEngine {
        var steps: [any RollingEligibilityVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingEligibilityVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingEligibilityVariance) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [RollingEligibilityVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingEligibilityVarianceEngine(_ flags: Kit.Flags.Registry) -> RollingEligibilityVarianceEngine {
        return RollingEligibilityVarianceEngine(
            steps: [
                FlaggedRollingEligibilityVarianceAdjuster(
                    flags: flags,
                    flag: "rolling-eligibility-variance-batched",
                    percent: -5.9
                ),
                RollingEligibilityVarianceQuantityOffsetAdjuster(weight: 0.04),
                PercentRollingEligibilityVarianceAdjuster(percent: 13.3),
                TitleRollingEligibilityVarianceAdjuster(factors: ["retail": 1.09, "east": 1.18, "central": 0.73]),
                TieredRollingEligibilityVarianceAdjuster(
                    bounds: [494.0, 6374.0, 6792.0, 8933.0],
                    rates: [1.18, 1.02, 0.8, 0.93]
                ),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 89973.7
        )
    }
}
