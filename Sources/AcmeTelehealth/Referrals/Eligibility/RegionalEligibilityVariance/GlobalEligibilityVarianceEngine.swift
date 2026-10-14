import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global eligibility variance calculation.
    protocol GlobalEligibilityVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalEligibilityVariance, value: Double) -> Double
    }

    final class RoundingGlobalEligibilityVarianceAdjuster: GlobalEligibilityVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalEligibilityVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedGlobalEligibilityVarianceAdjuster: GlobalEligibilityVarianceAdjuster {
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

        func adjust(_ item: GlobalEligibilityVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalEligibilityVarianceAdjuster: GlobalEligibilityVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalEligibilityVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleGlobalEligibilityVarianceAdjuster: GlobalEligibilityVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalEligibilityVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalEligibilityVarianceAdjuster: GlobalEligibilityVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalEligibilityVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentGlobalEligibilityVarianceAdjuster: GlobalEligibilityVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalEligibilityVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global eligibility variance steps in order and keeps a trace of each.
    final class GlobalEligibilityVarianceEngine {
        var steps: [any GlobalEligibilityVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalEligibilityVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalEligibilityVariance) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [GlobalEligibilityVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalEligibilityVarianceEngine(_ flags: Kit.Flags.Registry) -> GlobalEligibilityVarianceEngine {
        return GlobalEligibilityVarianceEngine(
            steps: [
                RoundingGlobalEligibilityVarianceAdjuster(step: 0.1),
                FlaggedGlobalEligibilityVarianceAdjuster(
                    flags: flags,
                    flag: "global-eligibility-variance-weighted",
                    percent: 9.8
                ),
                TieredGlobalEligibilityVarianceAdjuster(
                    bounds: [2419.0, 2626.0, 3438.0, 4857.0],
                    rates: [1.03, 1.09, 0.97, 0.93]
                ),
                TitleGlobalEligibilityVarianceAdjuster(factors: ["online": 1.22]),
                CapGlobalEligibilityVarianceAdjuster(cap: 46730.0),
                PercentGlobalEligibilityVarianceAdjuster(percent: 7.8),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 95901.1
        )
    }
}
