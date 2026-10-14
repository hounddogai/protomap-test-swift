import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped eligibility variance calculation.
    protocol CappedEligibilityVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: CappedEligibilityVariance, value: Double) -> Double
    }

    final class PercentCappedEligibilityVarianceAdjuster: CappedEligibilityVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedEligibilityVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedEligibilityVarianceAdjuster: CappedEligibilityVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedEligibilityVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCappedEligibilityVarianceAdjuster: CappedEligibilityVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedEligibilityVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedEligibilityVarianceAdjuster: CappedEligibilityVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedEligibilityVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCappedEligibilityVarianceAdjuster: CappedEligibilityVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedEligibilityVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCappedEligibilityVarianceAdjuster: CappedEligibilityVarianceAdjuster {
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

        func adjust(_ item: CappedEligibilityVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped eligibility variance steps in order and keeps a trace of each.
    final class CappedEligibilityVarianceEngine {
        var steps: [any CappedEligibilityVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedEligibilityVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedEligibilityVariance) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [CappedEligibilityVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedEligibilityVarianceEngine(_ flags: Kit.Flags.Registry) -> CappedEligibilityVarianceEngine {
        return CappedEligibilityVarianceEngine(
            steps: [
                PercentCappedEligibilityVarianceAdjuster(percent: 9.1),
                RoundingCappedEligibilityVarianceAdjuster(step: 0.1),
                CapCappedEligibilityVarianceAdjuster(cap: 14925.0),
                TieredCappedEligibilityVarianceAdjuster(
                    bounds: [1937.0, 4223.0, 5260.0, 7824.0],
                    rates: [0.93, 0.97, 0.86, 1.12]
                ),
                MinimumCappedEligibilityVarianceAdjuster(minimum: 14.6),
                FlaggedCappedEligibilityVarianceAdjuster(
                    flags: flags,
                    flag: "capped-eligibility-variance-rolling",
                    percent: -3.6
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 85856.5
        )
    }
}
